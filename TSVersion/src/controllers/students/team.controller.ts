import { Request, Response } from 'express';
import { assignPowerToStudent, getBlindnessAcFromStudent, getStudentById, getTeamFromStudent, getTeammates, rafflePower } from '../../services/student.service';
import { addStudentToTeam, getMembersFromTeam, getTeamByCode, removeStudFromTeam } from '../../services/team.service';
import { ApiError } from '../../middlewares/handleErrors';
import { LoginTeamReq } from '../../types/requests/students.types';
import { getTeamsFromCourse, getTeamsFromCourseWithStud } from '../../services/course.service';
import { StudentSocket, TeamResp, TeamSocket } from '../../types/responses/students.types';
import { getStudCurrTaskAttempt } from '../../services/taskAttempt.service';
import { OutgoingEvents, Power } from '../../types/enums';
import { PowerReq } from "../../types/requests/students.types";
import { Namespace, of } from '../../listeners/sockets';
import { TeamMember } from '../../types/Student.types';
import { directory, printStudentsDir } from '../../listeners/namespaces/students';
import { getTaskById } from '../../services/task.service';

export async function getTeams(req: Request, res: Response<TeamResp[]>, next: Function) {
    const { id: idStudent } = req.user!;
    try {
        const { id_course } = await getStudentById(idStudent);
        const teams = await getTeamsFromCourseWithStud(id_course, true);
        res.status(200).json(teams.map(({ code, id, name, students }) => ({
            id,
            name,
            code: code || '',
            students
        })));
    } catch (err) {
        next(err);
    }
}

export async function getCurrentTeam(req: Request, res: Response<TeamResp & {myPower?: Power}>, next: Function) {
    const { id: idStudent } = req.user!;
    try {
        const { id_team, name, code } = await getTeamFromStudent(idStudent);
        const members = await getMembersFromTeam({ idTeam: id_team });
        // const { id_course } = await getStudentById(idStudent);
        // const teams = await getTeamsFromCourseWithStud(id_course, true);
        res.status(200).json({
            id: id_team,
            name,
            code: code || '',
            myPower: members.find(m => m.id_student === idStudent)?.task_attempt.power,
            students: members.map(({ id_student, first_name, last_name, task_attempt: { power }, username }) => ({
                id: id_student,
                firstName: first_name,
                lastName: last_name,
                username,
                power
            }))
        });
    } catch (err) {
        next(err);
    }
}

export async function joinTeam(req: Request<LoginTeamReq>, res: Response, next: Function) {
    const { id: idStudent } = req.user!;

    const socket = directory.get(idStudent);
    if (!socket) return res.status(400).json({ message: 'Student is not connected' });

    const { code, taskOrder } = req.body as LoginTeamReq;

    if (!code || !taskOrder) return next(new ApiError('Missing code or taskOrder', 400));
    let prevTeam;
    try {
        prevTeam = await getTeamFromStudent(idStudent); // check if student is already in a team
    } catch (err) { } // no team found for student (expected)

    try {
        const team = await getTeamByCode(code);
        if (team.id_team === prevTeam?.id_team) throw new ApiError('Student is already in this team', 400);

        const student = await getStudentById(idStudent);
        if (student.id_course !== team.id_course) throw new ApiError('Student and team are not in the same course', 400);
        if (!team.active) throw new ApiError('Team is not active', 400);

        const teammates = await getMembersFromTeam({ idTeam: team.id_team });
        if (teammates.length >= 3) throw new ApiError('Team is full', 400);

        if (teammates.length) {
            // check if the team is already working on a different task
            const { id_task } = await getStudCurrTaskAttempt(teammates[0].id_student);
            const { task_order } = await getTaskById(id_task); 
            if (task_order !== taskOrder) throw new ApiError('This team is already working on a different task', 400);
        }
        
        await addStudentToTeam(idStudent, team.id_team, taskOrder);
        res.status(200).json({ message: 'Done' });

        // assign power + sockets (this could go to a subroutine)
        try { // if an error occurs, then it will not be sent to the next() function and the server will not crash
            socket.join('t' + team.id_team); // join student to team socket room

            getBlindnessAcFromStudent(idStudent).then(async ({ level }) => {
                let power: Power | null;
                try {
                    power = await assignPowerToStudent(idStudent, 'auto', teammates, level, false);
                } catch (err) {
                    console.log(err);
                    power = null;
                }

                let teamsData: TeamSocket[] | undefined; // for the course
                let teamData: StudentSocket[] | undefined; // for the team the student joined

                try {
                    teamsData = (await getTeamsFromCourseWithStud(team.id_course, true))
                        .map(({ code, id, name, students }) => ({
                            id,
                            name,
                            code: code || '',
                            students
                        }))
                } catch (err) {
                    console.log(err);
                }

                if (teamsData) {
                    socket.broadcast.to('c' + team.id_course).except('t' + team.id_team).emit(OutgoingEvents.TEAMS_UPDATE, teamsData);
                    teamData = teamsData.find(t => t.id === team.id_team)?.students;
                }
                if (!teamData) {
                    teamData = [
                        ...summMembers(teammates),
                        {
                            id: idStudent,
                            firstName: student.first_name,
                            lastName: student.last_name,
                            username: student.username,
                            power,
                        }
                    ];
                }
                socket.broadcast.to('t' + team.id_team).emit(OutgoingEvents.TEAM_UPDATE, teamData);
            }).catch(err => console.log(err));

            if (prevTeam) { // notify previous team that student left
                const nsp = of(Namespace.STUDENTS);
                if (!nsp) return;

                const idPrevTeam = prevTeam.id_team;
                getMembersFromTeam({ idTeam: idPrevTeam }).then(async (prevTeamMembers) => {
                    const teamData: StudentSocket[] = summMembers(prevTeamMembers);
                    nsp.to('t' + idPrevTeam).emit(OutgoingEvents.TEAM_UPDATE, teamData);
                }).catch(err => console.log(err));
            }
        } catch (err) {
            console.log(err);
        }
    } catch (err) {
        next(err);
    }
}

export async function leaveTeam(req: Request, res: Response, next: Function) {
    const { id: idStudent } = req.user!;

    const studSocket = directory.get(idStudent);
    if (!studSocket) return res.status(400).json({ message: 'Student is not connected' });

    try {
        const power = (await getStudCurrTaskAttempt(idStudent)).power;
        const { id_team, id_course } = await getTeamFromStudent(idStudent); // check if student is already in a team
        await removeStudFromTeam(idStudent);
        res.status(200).json({ message: 'Done' });

        try {
            studSocket.leave('t' + id_team); // leave student from team socket room
            // check if this student had super_hearing to assign it to another student
            if (power === Power.SuperHearing) {
                getMembersFromTeam({idTeam: id_team}).then(async (teammates) => {
                    if (!teammates.length) return; // no teammates left

                    const blindnessLevels = teammates.map(({ blindness_acuity: { level } }) => level);
                    const maxBlindnessLevel = Math.max(...blindnessLevels);
                    if (maxBlindnessLevel === 0) return; // no teammates with blindness

                    const withMaxBlindnessIdx = blindnessLevels.indexOf(maxBlindnessLevel);
                    const { id_student: idNewStudent } = teammates[withMaxBlindnessIdx];
                    const power = await assignPowerToStudent(idNewStudent, Power.SuperHearing, teammates);
                    // TODO: notify that student got super_hearing
                }).catch(err => console.log(err));
            }
            
            try{
                const teamsData = (await getTeamsFromCourseWithStud(id_course, true))
                    .map(({ code, id, name, students }) => ({
                        id,
                        name,
                        code: code || '',
                        students
                    }))
                studSocket.broadcast.to('c' + id_course).except('t' + id_team).emit(OutgoingEvents.TEAMS_UPDATE, teamsData);
            }catch(err){
                console.error(err);
            }

            const nsp = of(Namespace.STUDENTS);
            if (!nsp) return;
            getMembersFromTeam({ idTeam: id_team }).then(async (teamMembers) => {
                const teamData: StudentSocket[] = summMembers(teamMembers);
                nsp.to('t' + id_team).emit(OutgoingEvents.TEAM_UPDATE, teamData);
            }).catch(err => console.log(err));
        } catch (err) {
            console.log(err);
        }
    } catch (err) {
        next(err);
    }
}

export async function reqPower(req: Request, res: Response, next: Function) {
    const { power } = req.body as PowerReq;
    const { id: idStudent } = req.user!;
    try {
        const teammates = await getTeammates(idStudent);
        await assignPowerToStudent(idStudent, power, teammates);
        res.status(200).json({ message: 'Power assigned successfully' });
    } catch (err) {
        next(err);
    }
}

export async function ready(req: Request, res: Response, next: Function) {
    const { id: idStudent } = req.user!;
    try {
        const { power } = await getStudCurrTaskAttempt(idStudent);
        if (!power) return res.status(400).json({ message: 'You don\'t have any power' });
        res.status(200).json({ message: 'Ok' });
    } catch (err) {
        next(err);
    }
}

export async function reroll(req: Request, res: Response, next: Function) {
    const { id: idStudent } = req.user!;
    try {
        const power = await rafflePower(idStudent);
        if (!power) return res.status(304).json({ message: 'You got the same power' });

        // TODO: notify that student got new power

        res.status(200).json({ power });
    } catch (err) {
        next(err);
    }
}

// this should be in a separate file
const summMembers = (teammates: TeamMember[]): StudentSocket[] => ( // summarize members data to send to client
    teammates.map(({ id_student, first_name, last_name, username, task_attempt: { power } }) => ({
        id: id_student,
        firstName: first_name,
        lastName: last_name,
        username,
        power,
    }))
);

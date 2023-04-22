import { QueryTypes, Transaction } from "sequelize";
import sequelize from "@database/db";
import { ApiError } from "@middlewares/handleErrors";
import {
  BlindnessAcuityModel,
  ColorDeficiencyModel,
  CourseModel,
  StudentModel,
  VisualFieldDefectModel
} from "@models";
import { TeamMember } from "@interfaces/Team.types";
import { Team } from "@interfaces/Team.types";
import { BlindnessAcuity } from "@interfaces/BlindnessAcuity.types";
import {
  getCurrTaskAttempt,
  updateCurrTaskAttempt
} from "@services/taskAttempt.service";
import { Power } from "@interfaces/enums/taskAttempt.enum";
import {
  getAvailablePowers,
  getMembersFromTeam,
  notifyStudentOfTeamUpdate
} from "@services/team.service";
import { Course } from "@interfaces/Course.types";
import { notifyCourseOfTeamUpdate } from "@services/course.service";
import { TeamDetailDto } from "@dto/student/team.dto";
import { getRandomFloatBetween, parseUpdateFields } from "@utils";
import {
  StudentCreateDto,
  StudentDetailDto,
  StudentSummaryDto,
  StudentUpdateDto
} from "@dto/teacher/student.dto";
import * as repositoryService from "@services/repository.service";
import { StudentCreation } from "@interfaces/Student.types";

export async function getStudent(
  idTeacher: number,
  idCourse: number,
  idStudent: number
): Promise<StudentDetailDto> {
  const student = await repositoryService.findOne<StudentModel>(StudentModel, {
    where: { id_course: idCourse, id_student: idStudent, deleted: false },
    include: [
      {
        model: CourseModel,
        as: "course",
        where: { id_teacher: idTeacher, deleted: false }
      },
      {
        model: BlindnessAcuityModel,
        as: "blindnessAcuity",
        required: false,
        attributes: ["id_blindness_acuity", "name", "code"]
      },
      {
        model: VisualFieldDefectModel,
        as: "visualFieldDefect",
        required: false,
        attributes: ["id_visual_field_defect", "name", "code"]
      },
      {
        model: ColorDeficiencyModel,
        as: "colorDeficiency",
        required: false,
        attributes: ["id_color_deficiency", "name", "code"]
      }
    ]
  });
  if (!student) throw new ApiError("Student not found", 400);
  const {
    id_student,
    first_name,
    last_name,
    username,
    email,
    phone_code,
    phone_number,
    blindnessAcuity: {
      id_blindness_acuity,
      name: blindnessAcuityName,
      code: blindnessAcuityCode
    },
    visualFieldDefect: {
      id_visual_field_defect,
      name: visualFieldDefectName,
      code: visualFieldDefectCode
    },
    colorDeficiency: {
      id_color_deficiency,
      name: colorDeficiencyName,
      code: colorDeficiencyCode
    }
  } = student;
  return {
    id: id_student,
    firstName: first_name,
    lastName: last_name,
    username,
    email,
    phone: {
      countryCode: phone_code,
      number: phone_number
    },
    blindnessAcuity: {
      id: id_blindness_acuity,
      name: blindnessAcuityName,
      code: blindnessAcuityCode
    },
    visualFieldDefect: {
      id: id_visual_field_defect,
      name: visualFieldDefectName,
      code: visualFieldDefectCode
    },
    colorDeficiency: {
      id: id_color_deficiency,
      name: colorDeficiencyName,
      code: colorDeficiencyCode
    }
  };
}

export async function getStudents(
  idteacher: number,
  idCourse: number
): Promise<StudentSummaryDto[]> {
  const students = await repositoryService.findAll<StudentModel>(StudentModel, {
    where: { id_course: idCourse, deleted: false },
    include: [
      {
        model: CourseModel,
        as: "course",
        where: { id_teacher: idteacher, id_course: idCourse, deleted: false }
      }
    ]
  });
  return students.map(
    ({
      id_student,
      first_name,
      last_name,
      username,
      email,
      phone_code,
      phone_number
    }) => ({
      id: id_student,
      firstName: first_name,
      lastName: last_name,
      username: username,
      email: email,
      phone: {
        countryCode: phone_code,
        number: phone_number
      }
    })
  );
}

export async function createStudent(
  idTeacher: number,
  idCourse: number,
  fields: StudentCreateDto
): Promise<{ id: number }> {
  // check if course exists and belongs to teacher
  await repositoryService.findOne<CourseModel>(CourseModel, {
    where: { id_course: idCourse, id_teacher: idTeacher, deleted: false }
  });
  const {
    email,
    firstName,
    idBlindnessAcuity,
    idColorDeficiency,
    idVisualFieldDefect,
    lastName,
    password,
    phoneCode,
    phoneNumber,
    username
  } = fields;
  const { id_student } = await repositoryService.create<StudentModel>(
    StudentModel,
    {
      id_blindness_acuity: idBlindnessAcuity,
      id_color_deficiency: idColorDeficiency,
      id_visual_field_defect: idVisualFieldDefect,
      first_name: firstName,
      last_name: lastName,
      username,
      email,
      phone_code: phoneCode,
      phone_number: phoneNumber,
      password,
      id_course: idCourse
    }
  );
  return { id: id_student };
}

export async function updateStudent(
  idTeacher: number,
  idCourse: number,
  idStudent: number,
  fields: StudentUpdateDto
) {
  // check if course exists and belongs to teacher
  await repositoryService.findOne<CourseModel>(CourseModel, {
    where: { id_course: idCourse, id_teacher: idTeacher, deleted: false }
  });
  const parsedFields: Partial<StudentCreation> = parseUpdateFields<
    StudentUpdateDto,
    StudentCreation
  >(fields, {
    firstName: "first_name",
    idBlindnessAcuity: "id_blindness_acuity",
    idColorDeficiency: "id_color_deficiency",
    idVisualFieldDefect: "id_visual_field_defect",
    phoneCode: "phone_code",
    phoneNumber: "phone_number"
  });
  await repositoryService.update<StudentModel>(StudentModel, parsedFields, {
    where: { id_course: idCourse, id_student: idStudent, deleted: false }
  });
}

export async function deleteStudent(
  idTeacher: number,
  idCourse: number,
  idStudent: number
) {
  // check if course exists and belongs to teacher
  await repositoryService.findOne<CourseModel>(CourseModel, {
    where: { id_course: idCourse, id_teacher: idTeacher, deleted: false }
  });
  await repositoryService.update<StudentModel>(
    StudentModel,
    { deleted: true },
    {
      where: { id_course: idCourse, id_student: idStudent, deleted: false }
    }
  );
}

export async function getTeamFromStudent(idStudent: number): Promise<Team> {
  const team = (await sequelize.query(
    `
        SELECT t.* FROM team t
        JOIN task_attempt ta ON ta.id_team = t.id_team
        WHERE ta.id_student = ${idStudent} AND ta.active AND t.active
        LIMIT 1;
    `,
    { type: QueryTypes.SELECT }
  )) as Team[];
  if (!team.length) throw new ApiError("Team not found", 400);
  return team[0];
}

export async function getCurrentTeamFromStudent(
  idStudent: number
): Promise<TeamDetailDto & { myPower?: Power }> {
  const { id_team, name, code } = await getTeamFromStudent(idStudent);
  const members = await getMembersFromTeam({ idTeam: id_team });
  return {
    id: id_team,
    name,
    code: code || "",
    taskOrder: null,
    myPower: members.find((m) => m.id_student === idStudent)?.task_attempt
      .power,
    students: members.map(
      ({
        id_student,
        first_name,
        last_name,
        task_attempt: { power },
        username
      }) => ({
        id: id_student,
        firstName: first_name,
        lastName: last_name,
        username,
        power
      })
    )
  };
}

export async function getCourseFromStudent(idStudent: number): Promise<Course> {
  const course = (await sequelize.query(
    `
        SELECT c.* FROM course c
        JOIN student s ON s.id_course = c.id_course
        WHERE s.id_student = ${idStudent}
        LIMIT 1;
    `,
    { type: QueryTypes.SELECT }
  )) as Course[];
  if (!course.length) throw new ApiError("Course not found", 400);
  return course[0];
}

export async function getBlindnessAcFromStudent(
  idStudent: number
): Promise<BlindnessAcuity> {
  const blindness = await sequelize.query<BlindnessAcuity>(
    `
        SELECT ba.* FROM blindness_acuity ba
        JOIN student s ON s.id_blindness_acuity = ba.id_blindness_acuity
        WHERE s.id_student = ${idStudent};
    `,
    { type: QueryTypes.SELECT }
  );
  if (!blindness.length) throw new ApiError("Blindness not found", 400);
  return blindness[0];
}

async function assignPower(
  idStudent: number,
  power: Power,
  opts: { transaction?: Transaction } = {}
) {
  // prevent errors when updating teammate
  try {
    await updateCurrTaskAttempt(idStudent, { power });
  } catch (err) {}
}

export async function rafflePower(idStudent: number): Promise<false | Power> {
  // * Verify if the student has a visual illness
  const { level } = await getBlindnessAcFromStudent(idStudent);
  const { power } = await getCurrTaskAttempt(idStudent);

  // ** if the student has a visual illness and has super-hearing, return false
  if (level !== 0 && power === Power.SUPER_HEARING) return false;
  // * Get the student team
  const { id_team, id_course } = await getTeamFromStudent(idStudent);
  // * Get the available powers
  const powers = await getAvailablePowers(id_team);
  if (powers.length === 0) return false;

  // * raffle the powers
  const randomIdx = Math.floor(getRandomFloatBetween(-0.5, powers.length));
  // ** if the number is -1, return false
  if (randomIdx === -1) return false;
  // ** else, assign the power to the student
  await assignPower(idStudent, powers[randomIdx]);

  notifyCourseOfTeamUpdate(id_course, id_team, idStudent);
  notifyStudentOfTeamUpdate(idStudent);

  // * return the power
  return powers[randomIdx];
}

export async function assignPowerToStudent(
  idStudent: number,
  power: Power | "auto",
  teammates?: TeamMember[],
  blindnessLevel?: number,
  allowConflicts: boolean = true
): Promise<{
  power: Power;
  yaper: number | null;
}> {
  if (!teammates) teammates = await getTeammates(idStudent);
  if (teammates.length > 2) throw new ApiError("Team is full", 400);

  if (!blindnessLevel)
    blindnessLevel = (await getBlindnessAcFromStudent(idStudent)).level;
  const ids = teammates.map((member) => member.id_student);
  const currPowers = teammates.map((member) => member.task_attempt.power);
  const currBlindnessLevels = teammates.map(
    (member) => member.blindness_acuity_level
  );

  const getFreePowers = () => {
    return Object.values(Power).filter((power) => !currPowers.includes(power));
  };

  let yaper: number | null = null;
  if (power === "auto") {
    let autoPower: Power;

    const randomPowerBetween = (powers: Power[]) =>
      powers[Math.floor(Math.random() * powers.length)];

    if (blindnessLevel !== 0) {
      const withSuperHearingIdx = currPowers.indexOf(Power.SUPER_HEARING);
      if (withSuperHearingIdx === -1) {
        autoPower = Power.SUPER_HEARING;
      } else if (blindnessLevel > currBlindnessLevels[withSuperHearingIdx]) {
        await assignPower(ids[withSuperHearingIdx], getFreePowers()[0]); // assign free power to teammate with super_hearing
        yaper = ids[withSuperHearingIdx];
        autoPower = Power.SUPER_HEARING;
      } else {
        autoPower = randomPowerBetween(getFreePowers()); // assign free power to student
      }
    } else {
      autoPower = randomPowerBetween(getFreePowers());
    }
    await assignPower(idStudent, autoPower);
    return {
      power: autoPower,
      yaper
    };
  }

  if (power === Power.MEMORY_PRO || power === Power.SUPER_RADAR) {
    await assignPower(idStudent, power);
    if (!allowConflicts) {
      const withPowerIdx = currPowers.indexOf(power);
      if (withPowerIdx !== -1) {
        await assignPower(ids[withPowerIdx], getFreePowers()[0]); // assign free power to teammate with power
        yaper = ids[withPowerIdx];
      }
    }
  } else if (power === Power.SUPER_HEARING) {
    const withSuperHearingIdx = currPowers.indexOf(Power.SUPER_HEARING);
    if (withSuperHearingIdx === -1) await assignPower(idStudent, power);
    else if (blindnessLevel > currBlindnessLevels[withSuperHearingIdx]) {
      // there can't be conflict if student has higher blindness level
      await assignPower(ids[withSuperHearingIdx], getFreePowers()[0]); // assign free power to teammate with super_hearing
      yaper = ids[withSuperHearingIdx];
      await assignPower(idStudent, power);
    } else if (blindnessLevel === currBlindnessLevels[withSuperHearingIdx]) {
      if (!allowConflicts) {
        await assignPower(ids[withSuperHearingIdx], getFreePowers()[0]); // assign free power to teammate with super_hearing
        yaper = ids[withSuperHearingIdx];
      }
      await assignPower(idStudent, power);
    } else
      throw new ApiError(
        "Student has lower blindness level than teammate with super hearing",
        400
      );
  }
  return {
    power,
    yaper
  };
}

export async function getTeammates(
  idStudent: number,
  teamInfo?: { idTeam?: number; code?: string }
): Promise<TeamMember[]> {
  if (!teamInfo) {
    const { id_team: idTeam } = await getTeamFromStudent(idStudent);
    teamInfo = { idTeam };
  }
  return (await getMembersFromTeam(teamInfo)).filter(
    ({ id_student }) => id_student !== idStudent
  );
}

export function hasSocketConnection(idStudent: number) {}

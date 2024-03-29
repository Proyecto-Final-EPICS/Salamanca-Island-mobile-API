import { emitTo } from "@listeners/namespaces/student";
import { OutgoingEvents } from "@interfaces/enums/socket.enum";
import { getQuestionsFromTaskStageByTaskId } from "@services/question.service";
import { getPlayingTeamsFromCourse } from "@services/team.service";
import { Namespaces, of } from "@listeners/sockets";
interface Team {
  id: number;
  name: string;
  position: number;
  score: number;
}

const leaderBoards: Record<number, Team[]> = {};

export function getLeaderBoard(id: number): Team[] {
  return leaderBoards[id] || [];
}

//TODO: call the function in another places
export async function updateLeaderBoard(idCourse: number): Promise<void> {
  const teams = await getPlayingTeamsFromCourse(idCourse);
  console.log("teams", teams.length);
  if (!teams.length) {
    return;
  }

  /*
  console.log("teams", teams.length);
  /*/
  const numQuestions = (
    await getQuestionsFromTaskStageByTaskId(teams[0].taskAttempts[0].id_task, 2)
  ).length;
  //*

  // initialize the position
  let position = 0;

  console.log("numQuestions", numQuestions);
  // create the leaderboard
  const leaderboardScore = teams
    .map((team) => {
      // The score is proportional to the number of correct answers
      // The maximum score is 100 when all (or all - 1) answers are correct and the time is 0
      // const score = team.answers.reduce((acc, answer) => {
      const score = team.answers.reduce((acc, answer) => {
        const correct = answer.option?.correct;

        return acc + (correct ? 100 / numQuestions : 0);
      }, 0);

      return {
        id: team.id_team,
        name: team.name,
        score
      };
    })
    .sort((a, b) => b.score - a.score);

  console.log("leaderboard2", leaderboardScore);

  const leaderBoard = leaderboardScore.map((team, i, arr) => {
    // teams with the same score have the same position
    if (i > 0 && team.score === arr[i - 1].score) {
      return {
        id: team.id,
        name: team.name,
        score: team.score,
        position
      };
    } else {
      position = i + 1;

      return {
        id: team.id,
        name: team.name,
        score: team.score,
        position
      };
    }
  });

  console.log("leaderboard2", leaderBoard);

  // get not updated teams
  const notUpdatedTeams = leaderBoards[idCourse]
    ? leaderBoards[idCourse].filter(
        (team) =>
          !leaderBoard.some((t) => t.id === team.id) &&
          team.score >= 100 - 100 / numQuestions
      )
    : [];

  // leaderBoards[idCourse] = leaderBoard;
  // get biggest position of the not updated teams as an offset
  const offset = notUpdatedTeams.reduce(
    (acc, team) => (team.position > acc ? team.position : acc),
    0
  );

  // update the position of the new (updated) teams
  leaderBoard.forEach((team) => {
    team.position += offset;
  });

  // update the leaderboard
  const newLeaderBoard = [...notUpdatedTeams, ...leaderBoard].sort(
    (a, b) => b.position - a.position
  );

  // Check if the leaderboard has changed
  if (
    leaderBoards[idCourse] &&
    leaderBoards[idCourse].length === newLeaderBoard.length &&
    leaderBoards[idCourse].every(
      (team, i) => team.id === newLeaderBoard[i].id
    ) &&
    leaderBoards[idCourse].every(
      (team, i) => team.position === newLeaderBoard[i].position
    )
  ) {
    if (
      leaderBoards[idCourse].every(
        (team, i) => team.score === newLeaderBoard[i].score
      )
    ) {
      console.log("leaderboard not changed");
    } else {
      leaderBoards[idCourse] = newLeaderBoard;
    }
    return;
  }

  leaderBoards[idCourse] = newLeaderBoard;
  // emit the leaderboard
  emitLeaderboard(idCourse);
  //*/
}

export async function cleanLeaderBoard(idCourse: number): Promise<void> {
  leaderBoards[idCourse] = [];
}

export async function emitLeaderboard(idCourse: number): Promise<void> {
  if (!leaderBoards[idCourse]) {
    await updateLeaderBoard(idCourse);
    return;
  }

  const data = leaderBoards[idCourse].map((team) => ({
    id: team.id,
    name: team.name,
    position: team.position
  }));

  emitTo(`c${idCourse}`, OutgoingEvents.LEADER_BOARD_UPDATE, data);

  of(Namespaces.TEACHERS)
    ?.to(`c${idCourse}`)
    .emit(OutgoingEvents.LEADER_BOARD_UPDATE, data);
}

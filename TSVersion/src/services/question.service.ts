import { FindOptions, Op, QueryTypes } from "sequelize";
import sequelize from "@database/db";
import {
  AnswerModel,
  BlindnessAcuityModel,
  OptionModel,
  QuestionGroupModel,
  QuestionModel,
  StudentModel,
  TaskAttemptModel,
  TaskModel,
  TaskStageModel,
  TeamModel,
  TeamNameModel
} from "@models";
import { Question } from "@interfaces/Question.types";
import { ApiError } from "@middlewares/handleErrors";
import { QuestionDetailDto } from "@dto/global/question.dto";
import {
  QuestionPretaskDetailDto as QuestionPretaskDetailDtoStudent,
  QuestionDuringtaskDetailDto as QuestionDuringtaskDetailDtoStudent,
  QuestionPostaskDetailDto as QuestionPostaskDetailDtoStudent
} from "@dto/student/question.dto";
import {
  QuestionPretaskDetailDto as QuestionPretaskDetailDtoTeacher,
  QuestionDuringtaskDetailDto as QuestionDuringtaskDetailDtoTeacher,
  QuestionPostaskDetailDto as QuestionPostaskDetailDtoTeacher,
  QuestionsTaskDetailDto as QuestionsTaskDetailDtoTeacher
} from "@dto/teacher/question.dto";
import * as repositoryService from "@services/repository.service";
import { indexPower, separateTranslations, shuffle } from "@utils";
import { getCurrTaskAttempt } from "@services/taskAttempt.service";
import { getMembersFromTeam } from "./team.service";
import { QuestionType } from "@interfaces/enums/question.enum";
import { TaskStageMechanics } from "@interfaces/enums/taskStage.enum";
import { getQuestionGroupFromTeam } from "./questionGroup.service";
import { Power } from "@interfaces/enums/taskAttempt.enum";

// for teachers
export async function getQuestionsFromPretaskForTeacher(
  idTask: number
): Promise<QuestionPretaskDetailDtoTeacher[]> {
  return await getQuestionsFromTaskStage({ idTask }, 1);
}

export async function getQuestionsFromDuringtaskForTeacher(
  idTask: number
): Promise<QuestionDuringtaskDetailDtoTeacher[]> {
  return mapDuringtaskQuestionsForTeacher(
    await getQuestionsFromTaskStage({ idTask }, 2)
  );
}

export async function getQuestionsFromPostaskForTeacher(
  idTask: number
): Promise<QuestionPostaskDetailDtoTeacher[]> {
  return await getQuestionsFromTaskStage({ idTask }, 3);
}

export async function getQuestionsFromTaskForTeacher(
  idTask: number
): Promise<QuestionsTaskDetailDtoTeacher> {
  const questions = await getQuestions({ idTask });

  const pretask: QuestionModel[] = [];
  const duringtask: QuestionModel[] = [];
  const postask: QuestionModel[] = [];

  questions.forEach(async (question) => {
    const taskStageOrder = question.taskStage.task_stage_order;
    (taskStageOrder === 1
      ? pretask
      : taskStageOrder === 2
      ? duringtask
      : postask
    ).push(question);
  });

  return {
    pretask: mapQuestions(pretask),
    duringtask: mapDuringtaskQuestionsForTeacher(mapQuestions(duringtask)),
    postask: mapQuestions(postask)
  };
}

// for students
export async function getQuestionsFromPretaskForStudent(
  idStudent: number,
  taskOrder: number
): Promise<QuestionPretaskDetailDtoStudent[]> {
  let blindAcuityLevel: number | undefined;
  try {
    blindAcuityLevel = (
      await repositoryService.findOne<StudentModel>(StudentModel, {
        where: { id_student: idStudent, deleted: false },
        attributes: [],
        include: [
          {
            model: BlindnessAcuityModel,
            as: "blindnessAcuity",
            attributes: ["level"]
          }
        ]
      })
    ).blindnessAcuity.level;
  } catch (err) {
    console.log(err);
  }
  let questions = await getQuestionsFromTaskStage({ taskOrder }, 1);

  if (blindAcuityLevel !== undefined && blindAcuityLevel > 2) {
    questions = questions.filter(
      ({ type }) =>
        type !== QuestionType.ORDER &&
        type !== QuestionType.ORDERWORD &&
        type !== QuestionType.AUDIO_ORDERWORD &&
        type !== QuestionType.AUDIO_ORDER
    );
  }
  return questions.map(({ options, ...fields }) => ({
    ...fields,
    options: shuffle(options)
  }));
}

export async function getNextQuestionFromDuringtaskForStudent(
  idStudent: number,
  taskOrder: number
): Promise<QuestionDuringtaskDetailDtoStudent> {
  const { id_team, power, id_task } = await getCurrTaskAttempt(idStudent);

  // * Validations
  if (!id_team || !power) {
    throw new ApiError("No team or power found", 400);
  }

  let idQuestionGroup: number | undefined;

  const { mechanics } = await repositoryService.findOne<TaskStageModel>(
    TaskStageModel,
    { where: { task_stage_order: 2, id_task } }
  );

  const hidden =
    mechanics?.includes(TaskStageMechanics.HIDDEN_QUESTION) || false;

  if (mechanics?.includes(TaskStageMechanics.QUESTION_GROUP_TEAM_NAME)) {
    idQuestionGroup = (
      await getQuestionGroupFromTeam({
        idTeam: id_team,
        taskStageOrder: 2,
        idTask: id_task
      })
    ).id_question_group;
  }

  //* auxiliar variables to check if there are questions left
  let maxAnswers = -1;
  // let maxIncorrectAnswers = -1;

  // * Get all questios that have been not answered or answered incorrectly
  const missingQuestions = (
    await repositoryService.findAll<QuestionModel>(QuestionModel, {
      include: [
        {
          model: AnswerModel,
          as: "answers",
          where: { id_team },
          required: false,
          include: [
            {
              model: OptionModel,
              as: "option",
              required: true
            }
          ]
        },
        idQuestionGroup
          ? {
              model: QuestionGroupModel,
              as: "questionGroup",
              attributes: [],
              required: true,
              where: { id_question_group: idQuestionGroup }
            }
          : {},
        {
          model: TaskStageModel,
          as: "taskStage",
          attributes: [],
          where: { task_stage_order: 2, id_task },
          required: true
        }
      ].filter((elem) => Object.keys(elem).length)
    })
  ).filter(({ answers }) => {
    const answersCount = answers.length;
    const haveCorrectAnswer = answers.some(({ option }) => option!.correct);

    if (answersCount > maxAnswers) {
      maxAnswers = answersCount;
    }
    // if (!haveCorrectAnswer && answersCount > maxIncorrectAnswers) {
    //   maxIncorrectAnswers = answersCount;
    // }

    // return answers.every(({ option }) => !option.correct);
    return !haveCorrectAnswer;
  });

  console.log(
    "Missing questions: ",
    missingQuestions.map(({ question_order }) => question_order)
  );

  // const questionLeft = maxIncorrectAnswers < maxAnswers;

  // * Sort from the less answered to the most answered and from the lowest order to the highest order
  missingQuestions.sort((a, b) => {
    const aAnswers = a.answers.length;
    const bAnswers = b.answers.length;
    if (aAnswers !== bAnswers) {
      return aAnswers - bAnswers;
    }
    return a.question_order - b.question_order;
  });

  const nextQuestion =
    missingQuestions.length === 0 || //* If all questions have been answered
    (missingQuestions.length === 1 &&
      missingQuestions[0].answers?.length > 0 &&
      missingQuestions[0].answers.length >= maxAnswers) //* or there is only one question and it has been answered before (it is a retry)
      ? []
      : [missingQuestions[0]];

  const powers = (await getMembersFromTeam({ idTeam: id_team })).map(
    ({ task_attempt: { power } }) => power
  );
  powers.sort((a, b) => indexPower(a) - indexPower(b));
  const hiddenEnabled = hidden && powers.length > 1;

  const nextQuestionOrder = nextQuestion[0]?.question_order ?? -1;
  console.log("nextQuestionOrder", nextQuestionOrder);

  const questions = (
    await getQuestionsFromTaskStage(
      { taskOrder, idQuestionGroup },
      2,
      { question_order: nextQuestionOrder },
      { limit: 1 }
    )
  ).map(({ content, options, id, ...fields }) => {
    // TODO remove map and use only one question
    const {
      memoryPro: nouns,
      superRadar: preps,
      content: contentParsed
    } = separateTranslations(content);

    // * shuffle options
    const seed = (id_team + 1) * (id + 2);
    options = shuffle(options, seed);

    // * select the number of options based on the powers length (the correct option is always chosen)
    // options = shuffle(
    //   [
    //     options.filter(({ correct }) => correct)[0],
    //     ...options
    //       .filter(({ correct }) => !correct)
    //       .slice(0, powers.length * 2 - 1)
    //   ],
    //   seed
    // );
    options = shuffle(
      options.reduce(
        (acc: { cont: number; options: typeof options }, curr, i) => {
          /* 
            * An option is selected if:
            - It is correct
            - It is the hidden option and the hidden option is enabled
            - It is not the correct option and there are still options to be selected
          */
          if (curr.correct) {
            acc.options.push(curr);
          } else if (hidden && curr.content == "/HIDDEN QUESTION/") {
            if (hiddenEnabled) acc.options.push(curr);
          } else if (acc.cont < powers.length * 2 - 1 - +hiddenEnabled) {
            acc.options.push(curr);
            acc.cont++;
          }

          return acc;
        },
        { cont: 0, options: [] }
      ).options,
      seed
    );

    // * group options in groups of 2
    const optionGroups = options.reduce((acc, curr, i) => {
      if (i % 2 === 0) {
        acc.push([curr]);
      } else {
        acc[acc.length - 1].push(curr);
      }
      return acc;
    }, [] as (typeof options)[]);

    //// // * distribute options based on power
    //// options = distributeOptions(
    ////   options,
    ////   powers.indexOf(power) + 1,
    ////   powers.length
    //// );

    //* when hidden is enabled,
    //* check if some group has both the hidden option and the correct option
    //* and if so, separate them in different groups
    if (hiddenEnabled) {
      //- get the group with hidden and correct option index
      const hiddenCorrectGroupIndex = optionGroups.findIndex((group) =>
        group.every(
          ({ correct, content }) => correct || content == "/HIDDEN QUESTION/"
        )
      );
      if (hiddenCorrectGroupIndex !== -1) {
        //- get the group with hidden and correct option and the list of other groups
        const [hiddenCorrectGroup, otherGroups] = optionGroups.reduce(
          (acc, curr, i) => {
            if (i === hiddenCorrectGroupIndex) {
              acc[0] = curr;
            } else {
              acc[1].push(curr);
            }
            return acc;
          },
          [[], []] as [typeof options, (typeof options)[]]
        );

        //- select a random group from the list of other groups
        const otherGroup = shuffle(otherGroups, seed)[0];

        //- swap one option from each group
        const aux = hiddenCorrectGroup[0];
        hiddenCorrectGroup[0] = otherGroup[0];
        otherGroup[0] = aux;
      }
    }

    options = optionGroups[powers.indexOf(power)];

    return {
      id,
      content: contentParsed,
      ...fields,
      memoryPro: nouns,
      superRadar: preps,
      options
    };
  });
  if (!questions.length) throw new ApiError("Question not found", 404);

  if (hiddenEnabled) {
    if (
      questions[0].options.some(({ content }) => content == "/HIDDEN QUESTION/")
    ) {
      questions[0].options = questions[0].options = [];
    } else {
      switch (power) {
        case Power.MEMORY_PRO:
          questions[0].content = "{Hidden Question|Pregunta Oculta}";
          break;
        case Power.SUPER_RADAR:
          questions[0].content = "[Hidden Question|Pregunta oculta]";
          break;
        default:
          questions[0].content = "Hidden question";
      }
      // questions[0].content = "/HIDDEN QUESTION/";
      questions[0].hint = "Ask a teammate for the hidden question";
      questions[0].hint = "La pregunta la tiene un compañero0";
    }
  }

  return questions[0];
}

export async function getQuestionsFromPostaskForStudent(
  idStudent: number,
  taskOrder: number
): Promise<QuestionPostaskDetailDtoStudent[]> {
  const { id_task } = await repositoryService.findOne<TaskModel>(TaskModel, {
    where: { task_order: taskOrder }
  });

  let idQuestionGroup: number | undefined;

  const { mechanics } = await repositoryService.findOne<TaskStageModel>(
    TaskStageModel,
    { where: { task_stage_order: 3, id_task } }
  );

  if (mechanics.includes(TaskStageMechanics.QUESTION_GROUP_DURINGTASK_BASED)) {
    let idTeam: number | undefined;

    // use idTeam from most recent taskAttempt to know the questionGroup
    try {
      const recentTaskAttempt =
        await repositoryService.findOne<TaskAttemptModel>(TaskAttemptModel, {
          where: {
            id_student: idStudent,
            id_task,
            id_team: { [Op.not]: null }
          },
          order: [
            ["time_stamp", "DESC"],
            ["id_task_attempt", "DESC"]
          ]
        });
      idTeam = recentTaskAttempt.id_team!;
    } catch (err) {}

    const idTaskStage = (
      await repositoryService.findOne<TaskStageModel>(TaskStageModel, {
        where: { task_stage_order: 3, id_task: id_task }
      })
    ).id_task_stage;

    if (idTeam !== undefined) {
      idQuestionGroup = (
        await getQuestionGroupFromTeam({ idTeam, idTaskStage })
      ).id_question_group;
    } else {
      idQuestionGroup = (
        await repositoryService.findOne<QuestionGroupModel>(
          QuestionGroupModel,
          {
            attributes: ["id_question_group"],
            include: [
              {
                model: QuestionModel,
                as: "questions",
                required: true,
                attributes: [],
                where: { id_task_stage: idTaskStage }
              }
            ],
            order: sequelize.random()
          }
        )
      ).id_question_group;
    }
  }

  return (
    await getQuestionsFromTaskStage({ taskOrder, idQuestionGroup }, 3)
  ).map(({ options, ...fields }) => ({
    ...fields,
    options: shuffle(options)
  }));
}

export async function getQuestionsFromTaskStageByTaskId(
  idTask: number,
  taskStageOrder: number
): Promise<Question[]> {
  const questions = await sequelize.query<Question>(
    `
        SELECT q.* FROM question q
        JOIN task_stage ts ON q.id_task_stage = ts.id_task_stage AND ts.task_stage_order = ${taskStageOrder}
        JOIN task t ON ts.id_task = t.id_task AND t.id_task = ${idTask}
    `,
    { type: QueryTypes.SELECT }
  );
  return questions;
}

export async function getQuestionsFromTaskStage(
  taskFilter: { idTask?: number; taskOrder?: number; idQuestionGroup?: number },
  taskStageOrder?: number,
  where?: Partial<Question>,
  options?: FindOptions
): Promise<QuestionDetailDto[]> {
  const { idTask, taskOrder } = taskFilter;
  if (idTask === undefined && taskOrder === undefined) {
    throw new ApiError("idTask or taskOrder is required", 400);
  }
  return mapQuestions(
    await getQuestions(taskFilter, taskStageOrder, where, options)
  );
}

function mapQuestions(questions: QuestionModel[]): QuestionDetailDto[] {
  return questions.map(
    ({
      id_question,
      question_order,
      content,
      type,
      topic,
      img_alt,
      img_url,
      audio_url,
      video_url,
      hint,
      character,
      options
    }) => ({
      id: id_question,
      questionOrder: question_order,
      content,
      type,
      topic: topic || null,
      imgAlt: img_alt || null,
      imgUrl: img_url || null,
      audioUrl: audio_url || null,
      videoUrl: video_url || null,
      hint: hint || null,
      character: character || null,
      options: options.map(({ id_option, content, correct, feedback }) => ({
        id: id_option,
        content,
        correct,
        feedback: feedback || ""
      }))
    })
  );
}

async function getQuestions(
  {
    idTask,
    taskOrder,
    idQuestionGroup
  }: { idTask?: number; taskOrder?: number; idQuestionGroup?: number },
  taskStageOrder?: number,
  where?: Partial<Question>,
  options?: FindOptions
): Promise<QuestionModel[]> {
  return await repositoryService.findAll<QuestionModel>(QuestionModel, {
    where,
    include: [
      idQuestionGroup
        ? {
            model: QuestionGroupModel,
            as: "questionGroup",
            attributes: ["id_question_group"],
            required: true,
            where: { id_question_group: idQuestionGroup }
          }
        : {},
      {
        model: TaskStageModel,
        as: "taskStage",
        attributes: ["task_stage_order", "mechanics"],
        where:
          taskStageOrder !== undefined
            ? { task_stage_order: taskStageOrder }
            : undefined,
        required: true,
        include: [
          {
            model: TaskModel,
            as: "task",
            attributes: [],
            where:
              idTask !== undefined
                ? { id_task: idTask }
                : { task_order: taskOrder }
          }
        ]
      },
      {
        model: OptionModel,
        as: "options",
        required: false
      }
    ].filter((elem) => Object.keys(elem).length),
    order: [["question_order", "ASC"]],
    ...options
  });
}

function mapDuringtaskQuestionsForTeacher(
  questions: QuestionDetailDto[]
): QuestionDuringtaskDetailDtoTeacher[] {
  return questions.map(({ content, ...fields }) => {
    const {
      memoryPro: nouns,
      superRadar: preps,
      content: contentParsed
    } = separateTranslations(content);
    return {
      ...fields,
      content: contentParsed,
      memoryPro: nouns,
      superRadar: preps
    };
  });
}

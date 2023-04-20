export interface AnswerOptionReq {
  answerSeconds: number;
  idOption: number;
  newAttempt?: boolean | null;
}

export interface AnswerAudioReq {
  answerSeconds: number;
  audio: string;
  newAttempt?: boolean | null;
}

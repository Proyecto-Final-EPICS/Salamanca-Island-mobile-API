export interface CourseSummaryDto {
  id: number;
  name: string;
}

export interface CourseDetailDto extends CourseSummaryDto {
  session: boolean;
}

export interface CourseCreateDto {
  name: string;
}

export type CourseUpdateDto = Partial<CourseCreateDto>;

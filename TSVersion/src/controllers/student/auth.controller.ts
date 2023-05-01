import { Request, Response, NextFunction } from "express";
import passport from "passport";
import { signToken } from "@utils";
import { ApiError } from "@middlewares/handleErrors";
import { BlindnessAcuityModel, StudentModel } from "@models";
import { UserDto } from "@dto/student/auth.dto";

// login with passport
export async function login(req: Request, res: Response, next: NextFunction) {
  passport.authenticate("login-student", async (err, { id }, _info) => {
    try {
      if (err) {
        return next(new ApiError(err, 500));
      } else if (!id) {
        return next(new ApiError("Wrong credentials", 401));
      }
      req.login(id, { session: false }, async (err) => {
        if (err) return next(err);
        const token = signToken({ id });
        res.status(200).json({ token });
      });
    } catch (err) {
      console.error(err);
      return next(err);
    }
  })(req, res, next);
}

export async function whoami(
  req: Request,
  res: Response<UserDto>,
  next: NextFunction
) {
  const { id } = req.user!;

  try {
    const student = await StudentModel.findByPk(id, {
      attributes: ["id_student", "first_name", "last_name", "username"],
      include: [
        {
          model: BlindnessAcuityModel,
          attributes: ["id_blindness_acuity", "name"],
          as: "blindnessAcuity"
        }
      ]
    });

    if (!student) {
      return next(new ApiError("Student not found", 404));
    }
    const { id_student, first_name, last_name, username, blindnessAcuity } =
      student;

    res.status(200).json({
      id: id_student,
      firstName: first_name,
      lastName: last_name,
      username,
      visualCondition: blindnessAcuity.name
    });
  } catch (err: any) {
    throw new ApiError(err.message, 500);
  }
}

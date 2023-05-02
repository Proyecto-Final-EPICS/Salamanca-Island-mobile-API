import { Request, Response, NextFunction } from "express";
import passport from "passport";
import { signToken } from "@utils";
import { ApiError } from "@middlewares/handleErrors";
import { Role } from "@interfaces/enums/role.enum";

// login with passport
export async function login(req: Request, res: Response, next: NextFunction) {
  passport.authenticate("login-teacher", async (err, { id }, _info) => {
    try {
      if (err) {
        return next(new ApiError(err, 500));
      } else if (!id) {
        return next(new ApiError("Wrong credentials", 401));
      }
      req.login(id, { session: false }, async (err) => {
        if (err) return next(err);
        const token = signToken({ id, role: Role.TEACHER });
        res.status(200).json({ token });
      });
    } catch (err) {
      console.error(err);
      return next(err);
    }
  })(req, res, next);
}

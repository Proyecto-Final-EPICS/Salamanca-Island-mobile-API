import { Router } from "express";
import passport from "passport";
import { root } from "@controllers/student/task.controller";

const auth = passport.authenticate("jwt-student", { session: false });

const router = Router({ mergeParams: true });
router.use(auth);

router.get("/", root);

export default router;

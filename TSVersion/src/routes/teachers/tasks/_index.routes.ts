import { Router } from "express";
import passport from "passport";
import { getTasks } from "@controllers/teacher/task.controller";

const auth = passport.authenticate("jwt-teacher", { session: false });

const router = Router();
router.use(auth);

router.get("/", getTasks);

export default router;

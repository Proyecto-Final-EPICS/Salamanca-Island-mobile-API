// imports
import { DataTypes, ForeignKey, Model, NonAttribute } from "sequelize";
import sequelize from "@database/db";
import { comparePassword, hashPassword } from "@utils";
import { Student, StudentCreation } from "@interfaces/Student.types";
import {
  BlindnessAcuityModel,
  VisualFieldDefectModel,
  TaskAttemptModel,
  CourseModel,
  ColorDeficiencyModel
} from "@models";

// model class definition
class StudentModel extends Model<Student, StudentCreation> {
  declare id_student: number;
  declare id_course: ForeignKey<number>;
  declare id_blindness_acuity: ForeignKey<number>;
  declare id_visual_field_defect: ForeignKey<number>;
  declare id_color_deficiency: ForeignKey<number>;
  declare first_name: string;
  declare last_name: string;
  declare username: string;
  declare password: string;
  declare email?: string | null;
  declare phone_code?: string | null;
  declare phone_number?: string | null;
  declare deleted: boolean;

  declare course: NonAttribute<CourseModel>;
  declare blindnessAcuity: NonAttribute<BlindnessAcuityModel>;
  declare visualFieldDefect: NonAttribute<VisualFieldDefectModel>;
  declare colorDeficiency: NonAttribute<ColorDeficiencyModel>;
  declare taskAttempts: NonAttribute<TaskAttemptModel>;

  comparePassword = (password: string): boolean =>
    // comparePassword(password, this.password)
    password === this.password || comparePassword(password, this.password); // temporary
}

// model initialization
StudentModel.init(
  {
    id_student: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    id_course: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    id_blindness_acuity: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    id_visual_field_defect: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    id_color_deficiency: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    first_name: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    last_name: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    username: {
      type: DataTypes.STRING(50),
      unique: true,
      allowNull: false
    },
    password: {
      type: DataTypes.STRING(60), // 60 because of bcrypt
      allowNull: false
      // set(value: string) {
      //     this.setDataValue('password', hashPassword(value));
      // }
    },
    email: {
      type: DataTypes.STRING(320),
      unique: true
    },
    phone_code: {
      type: DataTypes.STRING(5)
    },
    phone_number: {
      type: DataTypes.STRING(15)
    },
    deleted: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false
    },
    comparePassword: {
      type: DataTypes.VIRTUAL
    }
  },
  {
    sequelize,
    modelName: "StudentModel",
    tableName: "student",
    timestamps: false,
    hooks: {
      beforeCreate: async (student: StudentModel) => {
        student.password = hashPassword(student.password);
      },
      beforeUpdate: async (student: StudentModel) => {
        if (student.changed("password")) {
          student.password = hashPassword(student.password);
        }
      }
    }
    // indexes: [
    //     {
    //         unique: true,
    //         fields: ['email']
    //     },
    //     {
    //         unique: true,
    //         fields: ['username']
    //     }
    // ]
  }
);

// model associations
// student and course
CourseModel.hasMany(StudentModel, {
  foreignKey: "id_course",
  as: "students"
});
StudentModel.belongsTo(CourseModel, {
  foreignKey: "id_course",
  as: "course"
});

// student and blindness_acuity
BlindnessAcuityModel.hasMany(StudentModel, {
  foreignKey: "id_blindness_acuity",
  as: "students"
});
StudentModel.belongsTo(BlindnessAcuityModel, {
  foreignKey: "id_blindness_acuity",
  as: "blindnessAcuity"
});

// student and visual_field_defect
VisualFieldDefectModel.hasMany(StudentModel, {
  foreignKey: "id_visual_field_defect",
  as: "students"
});
StudentModel.belongsTo(VisualFieldDefectModel, {
  foreignKey: "id_visual_field_defect",
  as: "visualFieldDefect"
});

// student and color_deficiency
ColorDeficiencyModel.hasMany(StudentModel, {
  foreignKey: "id_color_deficiency",
  as: "students"
});
StudentModel.belongsTo(ColorDeficiencyModel, {
  foreignKey: "id_color_deficiency",
  as: "colorDeficiency"
});

export default StudentModel;

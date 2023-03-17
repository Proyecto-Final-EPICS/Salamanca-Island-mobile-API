// imports
import { DataTypes, Model } from "sequelize";
import sequelize from "../database/db";
import { Institution, InstitutionCreation } from "../types/Institution.types";

// model class definition
class InstitutionModel extends Model<Institution, InstitutionCreation> {
  declare id_institution: number;
  declare name: string;
  declare nit: string;
  declare address: string;
  declare city: string;
  declare country: string;
  declare phone: string;
  declare email: string;
}

// model initialization
InstitutionModel.init(
  {
    id_institution: {
      type: DataTypes.SMALLINT,
      primaryKey: true,
      autoIncrement: true
    },
    name: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    nit: {
      type: DataTypes.STRING(9),
      allowNull: false
    },
    address: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    city: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    country: {
      type: DataTypes.STRING(100),
      allowNull: false
    },
    phone: {
      type: DataTypes.STRING(15),
      allowNull: false
    },
    email: {
      type: DataTypes.STRING(320),
      allowNull: false
    }
  },
  {
    sequelize,
    modelName: "InstitutionModel",
    tableName: "institution",
    timestamps: false
    // indexes: [
    //     {
    //         unique: true,
    //         fields: ['nit']
    //     }
    // ]
  }
);

export default InstitutionModel;

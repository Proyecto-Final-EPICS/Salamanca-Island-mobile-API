// creating the model for the Admin table
// imports
import { DataTypes, Model } from 'sequelize';
import sequelize from '../database';
import { comparePassword, hashPassword } from '../utils';
import { AdminModel } from '../types/Admins.types';

// model class definition
class Admin extends Model implements AdminModel {
    declare id_admin: number;
    declare first_name: string;
    declare last_name: string;
    declare email: string;
    declare username: string;
    declare password: string;
    comparePassword: ((password: string) => boolean) = password => (
        comparePassword(password, this.password)
    )
}

// model initialization
Admin.init({
    id_admin: {
        type: DataTypes.SMALLINT,
        primaryKey: true,
        autoIncrement: true
    },
    first_name: {
        type: DataTypes.STRING(100),
        allowNull: false
    },
    last_name: {
        type: DataTypes.STRING(100),
        allowNull: false
    },
    email: {
        type: DataTypes.STRING(320),
        unique: true,
        allowNull: false
    },
    username: {
        type: DataTypes.STRING(50),
        allowNull: false
    },
    password: {
        type: DataTypes.STRING(60), // 60 because of bcrypt
        allowNull: false,
        // set(value: string) {
        //     this.setDataValue('password', hashPassword(value));
        // }
    }
}, {
    sequelize,
    modelName: 'Admin',
    tableName: 'admin',
    timestamps: false,
    hooks: {
        beforeCreate: async (student: AdminModel) => {
            student.password = hashPassword(student.password);
        },
    },
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
});

export default Admin;
module.exports = Admin;
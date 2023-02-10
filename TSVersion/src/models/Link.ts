// creating the model for the Link table
// imports
import { DataTypes, Model } from 'sequelize';
import sequelize from '../database';
import Task from "./Task"
import { LinkModel } from '../types/Links.types';


// model class definition
class Link extends Model implements LinkModel {
    declare id_link: number;
    declare id_task: number;
    declare topic: string;
    declare url: string;
}

// model initialization
Link.init({
    id_link: {
        type: DataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true
    },
    id_task: {
        type: DataTypes.SMALLINT,
        allowNull: false
    },
    topic: {
        type: DataTypes.STRING(100),
        allowNull: false
    },
    url: {
        type: DataTypes.STRING(2048),
        allowNull: false
    }
}, {
    sequelize,
    modelName: 'Link',
    tableName: 'link',
    timestamps: false,
});

// model associations
Task.hasMany(Link, {
    foreignKey: 'id_task'
});

Link.belongsTo(Task, {
    foreignKey: 'id_task'
});

export default Link;
module.exports = Link;
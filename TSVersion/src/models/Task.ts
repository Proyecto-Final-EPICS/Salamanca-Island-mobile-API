// creating the model for the Task table
// imports
import { DataTypes, Model } from 'sequelize';
import sequelize from '../database';
import { Task, TaskCreation } from '../types/Task.types';

// model class definition
class TaskModel extends Model<Task, TaskCreation> {
    declare id_task: number;
    declare name: string;
    declare description: string;
    declare task_order: number;
    declare thumbnail_url: string;
    declare pretask_msg: string;
    declare duringtask_msg: string;
    declare postask_msg: string;
    declare deleted: boolean;
}

// model initialization
TaskModel.init({
    id_task: {
        type: DataTypes.SMALLINT,
        autoIncrement: true,
        primaryKey: true
    },
    task_order: {
        type: DataTypes.INTEGER,
        allowNull: false
    },
    name: {
        type: DataTypes.STRING(100),
        allowNull: false
    },
    description: {
        type: DataTypes.STRING(100),
        allowNull: false
    },
    long_description: {
        type: DataTypes.STRING(1000)
    },
    keywords: {
        type: DataTypes.ARRAY(DataTypes.STRING(50)),
        allowNull: false,
        defaultValue: []
    },
    pretask_msg: {
        type: DataTypes.STRING(100)
    },
    duringtask_msg: {
        type: DataTypes.STRING(100)
    },
    postask_msg: {
        type: DataTypes.STRING(100)
    },
    thumbnail_url: {
        type: DataTypes.STRING(2048)
    },
    deleted: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false
    }
}, {
    sequelize,
    modelName: 'TaskModel',
    tableName: 'task',
    timestamps: false
});

export default TaskModel;

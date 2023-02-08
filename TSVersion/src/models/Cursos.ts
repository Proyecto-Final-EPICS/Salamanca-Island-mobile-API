// imports
import { DataTypes } from 'sequelize';
import sequelize from '../database';
import Instituciones from './Instituciones';
import Profesores from './Profesores';
import { CursoModel } from '../types/Cursos.types';

// model definition
const Cursos = sequelize.define<CursoModel>('cursos', {
    id_curso: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true
    },
    nombre: {
        type: DataTypes.STRING,
        allowNull: false
    },
    descripcion: {
        type: DataTypes.STRING,
        allowNull: true
    },
    status: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false,
    },
    id_profesor: {
        type: DataTypes.INTEGER,
        allowNull: false,
    },
    id_institucion: {
        type: DataTypes.INTEGER,
        allowNull: false,
    }
}, {
    timestamps: false
});

// definir la relación entre Profesores y Cursos
Profesores.hasMany(Cursos, {
    foreignKey: 'id_profesor'
});
Cursos.belongsTo(Profesores, {
    foreignKey: 'id_profesor'
});

// definir la relación entre Instituciones y Cursos
Instituciones.hasMany(Cursos, {
    foreignKey: 'id_institucion'
});
Cursos.belongsTo(Instituciones, {
    foreignKey: 'id_institucion'
});

export default Cursos;
module.exports = Cursos;
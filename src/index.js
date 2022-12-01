// a expressjs based application
// imports and requires
const express = require('express');

//INITIALIZE
const app = express();
require('./auth/passport');
const sequelize = require('./database');
require('./models/init-db');

// SETTINGS
app.set('port', process.env.PORT || 3000);

// MIDLEWARES
app.use(require('cors')());
app.use(require('morgan')('dev'));
app.use(express.urlencoded({extended: false}));
app.use(express.json());

// ROUTES
app.use('/api', require('./routes/auth.routes'));
app.use('/api/task', require('./routes/task.routes'));
app.use('/api/pretask', require('./routes/pretask.routes'));
app.use('/api/pregunta', require('./routes/pregunta.routes'));

// check server status
app.get('/', (req, res) => {
    res.send('Server is running');
});

// STARTING THE SERVER
app.listen(app.get('port'), async () => {
    try{
        sequelize.authenticate().then(() => {
            console.log('Connection has been established successfully.');
            console.log('Database is connected');
            sequelize.sync();
        }).catch(err => {
            console.error('Unable to connect to the database:', err);
        });
    }catch(error){
        console.log('database Error: ', error);
    }
    console.log('Server on port', app.get('port'));
});

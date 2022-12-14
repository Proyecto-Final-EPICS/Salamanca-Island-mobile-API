//* Charge environmental variables
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({override: true});
const result = dotenv.config({ path: path.join(__dirname, `../.env.${process.env.NODE_ENV}`) });
if (process.env.NODE_ENV && result.error) {
    throw result.error;
}

//* Express aplication
import express from 'express';
const app = express();
// imports
import cors from 'cors';
import morgan from 'morgan';
require('./database');
require('./models/init-db');
require('./auth/passport');
import swaggerUi from 'swagger-ui-express';
const swaggerDocument = require('../openapi.json');

//* Express configuration and middlewares
app.set('port', process.env.PORT || 3000);
app.use(cors());
app.use(morgan('dev'));
app.use(express.urlencoded({extended: false}));
app.use(express.json());

//* Routes
import indexRoutes from './routes';
app.use(indexRoutes);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

//* handlers
// catch 404 and forward to error handler
import notFoundHandler from './middlewares/notFound';
app.use(notFoundHandler);

import errorHandler from './middlewares/handleErrors';
app.use(errorHandler);

export default app;
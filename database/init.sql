-- THIS IS A POSTGRESQL INITIALIZATION FILE
-- TODO: check order of creation of tables to avoid errors
DROP DATABASE IF EXISTS mydb;
CREATE DATABASE mydb;
\connect mydb;

-- CREATING TABLES
-- CREATING TABLE blindness_acuity
CREATE TABLE blindness_acuity (
    id_blindness_acuity SMALLSERIAL NOT NULL,
    name VARCHAR(50) NOT NULL,
    code VARCHAR(50) NOT NULL,
    level SMALLINT NOT NULL,
    worse_than VARCHAR(200),
    better_eq_than VARCHAR(200),
    -- CONSTRAINTS
    CONSTRAINT pk_blindness_acuity PRIMARY KEY (id_blindness_acuity),
    CONSTRAINT uk_blindness_acuity_code UNIQUE (code)
);

-- CREATING TABLE color_deficiency
CREATE TABLE color_deficiency (
    id_color_deficiency SMALLSERIAL NOT NULL,
    name VARCHAR(50) NOT NULL,
    code VARCHAR(50) NOT NULL,
    description VARCHAR(1000) NOT NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_color_deficiency PRIMARY KEY (id_color_deficiency),
    CONSTRAINT uk_color_deficiency_code UNIQUE (code)
);

-- CREATING TABLE visual_field_defect
CREATE TABLE visual_field_defect (
    id_visual_field_defect SMALLSERIAL NOT NULL,
    name VARCHAR(50) NOT NULL,
    code VARCHAR(50) NOT NULL,
    description VARCHAR(1000) NOT NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_visual_field_defect PRIMARY KEY (id_visual_field_defect),
    CONSTRAINT uk_visual_field_defect_code UNIQUE (code)
);

-- CREATING TABLE task
CREATE TABLE task (
    id_task SMALLSERIAL NOT NULL,
    task_order SMALLINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(200) NOT NULL,
    long_description VARCHAR(1000),
    keywords VARCHAR(50)[] NOT NULL DEFAULT '{}',
    thumbnail_url VARCHAR(2048),
    thumbnail_alt VARCHAR(50),
    coming_soon BOOLEAN NOT NULL DEFAULT FALSE,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    -- CONSTRAINTS
    CONSTRAINT pk_task PRIMARY KEY (id_task),
    CONSTRAINT uk_task_task_order UNIQUE (task_order)
);

-- CREATING TABLE task_stage
CREATE TABLE task_stage (
    id_task_stage SMALLSERIAL NOT NULL,
    id_task SMALLINT NOT NULL,
    task_stage_order SMALLINT NOT NULL,
    description VARCHAR(100) NOT NULL,
    keywords VARCHAR(50)[] NOT NULL DEFAULT '{}',
    -- CONSTRAINTS
    CONSTRAINT pk_task_stage PRIMARY KEY (id_task_stage),
    CONSTRAINT pk_task_stage_task FOREIGN KEY (id_task) REFERENCES task(id_task),
    CONSTRAINT uk_task_stage_constr UNIQUE (id_task, task_stage_order),
    CONSTRAINT check_task_stage_order CHECK (task_stage_order IN (1, 2, 3)) -- 1: pretask, 2: duringtask, 3: posttask
);

CREATE TYPE valid_question_type AS ENUM ('flashcard', 'fill', 'order', 'select', 'audio', 'audio_select', 'audio_order', 'audio_speaking');
CREATE TYPE valid_question_topic AS ENUM ('vocabulary', 'prepositions');

-- CREATING TABLE question
CREATE TABLE question (
    id_question SERIAL NOT NULL,
    id_task_stage SMALLINT NOT NULL,
    question_order SMALLINT NOT NULL,
    content VARCHAR(200) NOT NULL,
    audio_url VARCHAR(2048),
    video_url VARCHAR(2048),
    type VALID_QUESTION_TYPE NOT NULL,
    img_alt VARCHAR(50),
    img_url VARCHAR(2048),
    topic VALID_QUESTION_TOPIC,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    -- CONSTRAINTS
    CONSTRAINT pk_question PRIMARY KEY (id_question),
    CONSTRAINT fk_question_task FOREIGN KEY (id_task_stage) REFERENCES task_stage(id_task_stage),
    CONSTRAINT uk_question_constr UNIQUE (id_task_stage, question_order)
);

-- CREATING TABLE option
CREATE TABLE option (
    id_option SERIAL NOT NULL,
    id_question INTEGER NOT NULL,
    content VARCHAR(1000) NOT NULL,
    feedback VARCHAR(100),
    correct BOOLEAN NOT NULL,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    -- CONSTRAINTS
    CONSTRAINT pk_option PRIMARY KEY (id_option),
    CONSTRAINT fk_option_question FOREIGN KEY (id_question) REFERENCES question(id_question)
);

-- CREATING TABLE institution
CREATE TABLE institution (
    id_institution SMALLSERIAL NOT NULL,
    name VARCHAR(100) NOT NULL,
    nit CHAR(9) NOT NULL,
    address VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    email VARCHAR(320) NOT NULL,
    phone_code VARCHAR(5) NOT NULL,
    phone_number VARCHAR(15) NOT NULL,
    website_url VARCHAR(2048),
    -- CONSTRAINTS
    CONSTRAINT pk_institution PRIMARY KEY (id_institution),
    CONSTRAINT uk_institution_nit UNIQUE (nit),
    CONSTRAINT uk_institution_email UNIQUE (email)
);

-- CREATING TABLE admin
CREATE TABLE admin (
    id_admin SMALLSERIAL NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(320) NOT NULL,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(60) NOT NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_admin PRIMARY KEY (id_admin),
    CONSTRAINT uk_admin_email UNIQUE (email),
    CONSTRAINT uk_admin_username UNIQUE (username)
);

-- CREATING TABLE teacher
CREATE TABLE teacher (
    id_teacher SMALLSERIAL NOT NULL,
    id_institution SMALLINT NOT NULL,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(60) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(320) NOT NULL,
    phone_code VARCHAR(5) NOT NULL,
    phone_number VARCHAR(15) NOT NULL,
    -- CONSTRAINTS
    CONSTRAINT pk_teacher PRIMARY KEY (id_teacher),
    CONSTRAINT fk_teacher_institution FOREIGN KEY (id_institution) REFERENCES institution(id_institution),
    CONSTRAINT uk_teacher_email UNIQUE (email),
    CONSTRAINT uk_teacher_username UNIQUE (username)
);

-- CREATING TABLE course
CREATE TABLE course (
    id_course SMALLSERIAL NOT NULL,
    id_teacher SMALLINT NOT NULL,
    id_institution SMALLINT NOT NULL,
    name VARCHAR(50) NOT NULL,
    session BOOLEAN NOT NULL DEFAULT FALSE,
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    -- CONSTRAINTS
    CONSTRAINT pk_course PRIMARY KEY (id_course),
    CONSTRAINT fk_course_teacher FOREIGN KEY (id_teacher) REFERENCES teacher(id_teacher),
    CONSTRAINT fk_course_institution FOREIGN KEY (id_institution) REFERENCES institution(id_institution)
);

-- CREATING TABLE team
CREATE TABLE team (
    id_team SERIAL NOT NULL,
    id_course SMALLINT NOT NULL,
    name VARCHAR(50) NOT NULL,
    code CHAR(6),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    playing BOOLEAN NOT NULL DEFAULT FALSE,
    -- CONSTRAINTS
    CONSTRAINT pk_team PRIMARY KEY (id_team),
    CONSTRAINT fk_team_course FOREIGN KEY (id_course) REFERENCES course(id_course)
);
CREATE UNIQUE INDEX idx_team_active_code ON team (code) WHERE active; -- code is unique only if the team is active

-- CREATING TABLE student
CREATE TABLE student (
    id_student SERIAL NOT NULL,
    id_course SMALLINT NOT NULL,
    id_blindness_acuity SMALLINT NOT NULL,
    id_visual_field_defect SMALLINT NOT NULL,
    id_color_deficiency SMALLINT NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    username VARCHAR(50) NOT NULL,
    password VARCHAR(60) NOT NULL,
    email VARCHAR(320),
    phone_code VARCHAR(5),
    phone_number VARCHAR(15),
    deleted BOOLEAN NOT NULL DEFAULT FALSE,
    -- CONSTRAINTS
    CONSTRAINT pk_student PRIMARY KEY (id_student),
    CONSTRAINT fk_student_course FOREIGN KEY (id_course) REFERENCES course(id_course),
    CONSTRAINT fk_student_blindness_acuity FOREIGN KEY (id_blindness_acuity) REFERENCES blindness_acuity(id_blindness_acuity),
    CONSTRAINT fk_student_visual_field_defect FOREIGN KEY (id_visual_field_defect) REFERENCES visual_field_defect(id_visual_field_defect),
    CONSTRAINT fk_student_color_deficiency FOREIGN KEY (id_color_deficiency) REFERENCES color_deficiency(id_color_deficiency),
    CONSTRAINT uk_student_email UNIQUE (email),
    CONSTRAINT uk_student_username UNIQUE (username)
);

-- CREATING TABLE student_task
CREATE TABLE student_task (
    id_student_task SERIAL NOT NULL,
    id_student INTEGER NOT NULL,
    id_task SMALLINT NOT NULL,
    highest_stage SMALLINT NOT NULL DEFAULT 0, -- 0: not started, 1: pretask, 2: duringtask, 3: postask
    -- CONSTRAINTS
    CONSTRAINT pk_student_task PRIMARY KEY (id_student_task),
    CONSTRAINT fk_student_task_student FOREIGN KEY (id_student) REFERENCES student(id_student),
    CONSTRAINT fk_student_task_task FOREIGN KEY (id_task) REFERENCES task(id_task),
    CONSTRAINT uk_student_task UNIQUE (id_student, id_task),
    CONSTRAINT check_student_task_highest_stage CHECK (highest_stage >= 0 AND highest_stage <= 3)
);

CREATE TYPE valid_power AS ENUM ('super_hearing', 'memory_pro', 'super_radar');

-- CREATING TABLE task_attempt
CREATE TABLE task_attempt (
    id_task_attempt SERIAL NOT NULL,
    id_task SMALLINT NOT NULL,
    id_team INTEGER,
    id_student INTEGER NOT NULL,
    power VALID_POWER,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    time_stamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINTS
    CONSTRAINT pk_task_attempt PRIMARY KEY (id_task_attempt),
    CONSTRAINT fk_task_attempt_task FOREIGN KEY (id_task) REFERENCES task(id_task),
    CONSTRAINT fk_task_attempt_team FOREIGN KEY (id_team) REFERENCES team(id_team),
    CONSTRAINT fk_task_attempt_student FOREIGN KEY (id_student) REFERENCES student(id_student)
    -- CONSTRAINT check_task_attempt_power_not_null CHECK (id_team IS NULL OR power IS NOT NULL)
);
CREATE UNIQUE INDEX idx_task_attempt_active_id_student ON task_attempt (id_student) WHERE active; -- id_student is unique if the task_attempt is active
-- CREATE UNIQUE INDEX idx_task_attempt_active_power_id_team ON task_attempt (power, id_team) WHERE active; -- power and id_team are unique if the task_attempt is active

-- CREATING TABLE answer
CREATE TABLE answer (
    id_answer SERIAL NOT NULL,
    id_question INTEGER NOT NULL,
    id_option INTEGER,
    id_task_attempt INTEGER NOT NULL,
    id_team INTEGER,
    answer_seconds INTEGER,
    audio_url VARCHAR(2048),
    -- CONSTRAINTS
    CONSTRAINT pk_answer PRIMARY KEY (id_answer),
    CONSTRAINT fk_answer_question FOREIGN KEY (id_question) REFERENCES question(id_question),
    CONSTRAINT fk_answer_option FOREIGN KEY (id_option) REFERENCES option(id_option),
    CONSTRAINT fk_answer_task_attempt FOREIGN KEY (id_task_attempt) REFERENCES task_attempt(id_task_attempt),
    CONSTRAINT fk_answer_team FOREIGN KEY (id_team) REFERENCES team(id_team)
    -- CONSTRAINT uk_answer UNIQUE (id_task_attempt, id_question, id_option) -- a student can only answer a question once per task_attempt
);

-- CREATING TABLE release (mobile app releases)
CREATE TABLE release (
    id_release SMALLSERIAL NOT NULL,
    version VARCHAR(16) NOT NULL,
    url VARCHAR(2048) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- CONSTRAINTS
    CONSTRAINT pk_release PRIMARY KEY (id_release),
    CONSTRAINT uk_release_url UNIQUE (url),
    CONSTRAINT uk_release_version UNIQUE(version)
);

-- TODO: create table Animal
-- TODO: create table Historial

-- FUNCTIONS
-- INSERT INTO student_task when a new student is inserted
CREATE OR REPLACE FUNCTION insert_student_task_for_new_student()
RETURNS TRIGGER AS $$
DECLARE
    new_student_id INTEGER;
    task_id SMALLINT; -- to iterate over the tasks
BEGIN
    -- Get the ID of the newly inserted student
    new_student_id = (SELECT id_student FROM student ORDER BY id_student DESC LIMIT 1);
    -- Insert a record into the student_task table for each task
    FOR task_id IN (SELECT id_task FROM task) LOOP
        RAISE NOTICE 'Inserting student_task for student % and task %', new_student_id, task_id;
        INSERT INTO student_task (id_student, id_task)
        VALUES (new_student_id, task_id);
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- INSERT INTO student_task when a new task is inserted
CREATE OR REPLACE FUNCTION insert_student_task_for_new_task()
RETURNS TRIGGER AS $$
DECLARE
    new_task_id SMALLINT;
    student_id INTEGER; -- to iterate over the students
BEGIN
    -- Get the ID of the newly inserted task
    new_task_id = (SELECT id_task FROM task ORDER BY id_task DESC LIMIT 1);
    -- Insert a record into the student_task table for each student
    FOR student_id IN (SELECT id_student FROM student) LOOP
        RAISE NOTICE 'Inserting student_task for student % and task %', student_id, new_task_id;
        INSERT INTO student_task (id_student, id_task)
        VALUES (student_id, new_task_id);
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- INSERT INTO task_stage when a new task is inserted (3 stages per task)
CREATE OR REPLACE FUNCTION insert_task_stage_for_new_task()
RETURNS TRIGGER AS $$
DECLARE
    new_task_id INTEGER;
BEGIN
    -- Get the ID of the newly inserted task
    new_task_id = (SELECT id_task FROM task ORDER BY id_task DESC LIMIT 1);
    -- Insert 3 records into the task_stage table
    -- Stage 1
    INSERT INTO task_stage (id_task, task_stage_order, description)
    VALUES (new_task_id, 1, 'Description for Stage 1');
    -- Stage 2
    INSERT INTO task_stage (id_task, task_stage_order, description)
    VALUES (new_task_id, 2, 'Description for Stage 2');
    -- Stage 3
    INSERT INTO task_stage (id_task, task_stage_order, description)
    VALUES (new_task_id, 3, 'Description for Stage 3');
    RAISE NOTICE 'Inserted 3 task_stage records for task %', new_task_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Throw exception if all team members don't doing the same task
CREATE OR REPLACE FUNCTION validate_team_task() RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM task_attempt t1
    WHERE t1.id_team = NEW.id_team AND t1.id_task <> NEW.id_task AND t1.active
  ) THEN
    RAISE EXCEPTION 'Team members must be doing the same task';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Throw exception if team not active is playing
CREATE OR REPLACE FUNCTION validate_team_playing() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.active = FALSE AND NEW.playing = TRUE THEN
    RAISE EXCEPTION 'Team not active cannot be playing';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGERS
-- Trigger to insert records into the student_task table for each new student
CREATE TRIGGER insert_student_task_for_new_student_trigger
AFTER INSERT ON student
FOR EACH ROW
EXECUTE FUNCTION insert_student_task_for_new_student();

-- Trigger to insert records into the student_task table for each new task
CREATE TRIGGER insert_student_task_for_new_task_trigger
AFTER INSERT ON task
FOR EACH ROW
EXECUTE FUNCTION insert_student_task_for_new_task();

-- Trigger to insert records into the task_stage table for each new task
CREATE TRIGGER insert_task_stage_for_new_task_trigger
AFTER INSERT ON task
FOR EACH ROW
EXECUTE FUNCTION insert_task_stage_for_new_task();

-- Trigger to check that all team members are doing the same task
CREATE TRIGGER validate_team_task_trigger
BEFORE INSERT OR UPDATE ON task_attempt
FOR EACH ROW
EXECUTE FUNCTION validate_team_task();

-- Trigger to check that a team cannot be inactive and playing at the same time
CREATE TRIGGER validate_team_playing_trigger
BEFORE INSERT OR UPDATE ON team
FOR EACH ROW
EXECUTE FUNCTION validate_team_playing();

-- INSERTING DATA

-- INSERT INTO blindness_acuity
INSERT INTO blindness_acuity (code, name, level, worse_than, better_eq_than) VALUES ('none', 'Ninguna', 0, NULL, '6/12 | 5/10 (0.5) | 20/40 | 0.3');
INSERT INTO blindness_acuity (code, name, level, worse_than, better_eq_than) VALUES ('mild', 'Leve', 1, '6/12 | 5/10 (0.5) | 20/40 | 0.3', '6/18 | 3/10 (0.3) | 20/70 | 0.5');
INSERT INTO blindness_acuity (code, name, level, worse_than, better_eq_than) VALUES ('moderate', 'Moderada', 2, '6/18 | 3/10 (0.3) | 20/70 | 0.5', '6/60 | 1/10 (0.1) | 20/200 | 1.0');
INSERT INTO blindness_acuity (code, name, level, worse_than, better_eq_than) VALUES ('severe', 'Severa', 3, '6/60 | 1/10 (0.1) | 20/200 | 1.0', '3/60 | 1/20 (0.05) | 20/400 | 1.3');
INSERT INTO blindness_acuity (code, name, level, worse_than, better_eq_than) VALUES ('blindness_4', 'Ceguera (categoría 4)', 4, '3/60 | 1/20 (0.05) | 20/400 | 1.3', '1/60 | 1/50 (0.02) | 20/1200 | 1.8');
INSERT INTO blindness_acuity (code, name, level, worse_than, better_eq_than) VALUES ('blindness_5', 'Ceguera (categoría 5)', 5, '1/60 | 1/50 (0.02) | 5/300 (20/1200) | 1.8', 'Percepción de luz');
INSERT INTO blindness_acuity (code, name, level, worse_than, better_eq_than) VALUES ('blindness_6', 'Ceguera (categoría 6)', 6, 'Sin percepción de luz', NULL);

-- INSERT INTO color_deficiency
INSERT INTO color_deficiency (code, name, description) VALUES ('none', 'Ninguna', 'No tiene ninguna deficiencia de percepción de color.');
INSERT INTO color_deficiency (code, name, description) VALUES ('protanopia', 'Protanopía', 'Sensitividad nula hacia la luz roja. El individuo no puede distinguir entre el rojo y el verde.');
INSERT INTO color_deficiency (code, name, description) VALUES ('protanomaly', 'Protanomalía', 'Sensitividad reducida hacia la luz roja. El individuo tiene dificultades para distinguir entre el rojo y el verde.');
INSERT INTO color_deficiency (code, name, description) VALUES ('deuteranopia', 'Deuteranopía', 'Sensitividad nula hacia la luz verde. El individuo no puede distinguir entre el verde y el amarillo.');
INSERT INTO color_deficiency (code, name, description) VALUES ('deuteranomaly', 'Deuteranomalía', 'Sensitividad reducida hacia la luz verde. El individuo tiene dificultades para distinguir entre el verde y el amarillo.');
INSERT INTO color_deficiency (code, name, description) VALUES ('tritanopia', 'Tritanopía', 'Sensitividad nula hacia la luz azul. El individuo no puede distinguir entre el azul y el amarillo.');
INSERT INTO color_deficiency (code, name, description) VALUES ('tritanomaly', 'Tritanomalía', 'Sensitividad reducida hacia la luz azul. El individuo tiene dificultades para distinguir entre el azul y el amarillo.');
INSERT INTO color_deficiency (code, name, description) VALUES ('achromatopsia', 'Achromatopsia', 'El individuo no puede distinguir entre los colores.');
INSERT INTO color_deficiency (code, name, description) VALUES ('achromatomaly', 'Achromatomalía', 'El individuo tiene dificultades para distinguir entre los colores.');

-- INSERT INTO visual_field_defect
INSERT INTO visual_field_defect (code, name, description) VALUES ('none', 'Ninguna', 'No tiene ninguna deficiencia en el campo visual.');
INSERT INTO visual_field_defect (code, name, description) VALUES ('scotoma', 'Escotoma', 'Un punto ciego en el campo visual que puede ser causado por varias condiciones, como el glaucoma o una lesión cerebral.');
INSERT INTO visual_field_defect (code, name, description) VALUES ('quadrantanopia', 'Cuadrantanopsia', 'Una condición en la que se pierde una cuarta parte del campo visual, típicamente en un cuadrante.');
INSERT INTO visual_field_defect (code, name, description) VALUES ('tunnel_vision', 'Visión de túnel', 'Una condición en la que se pierde la visión periférica, dejando solo un pequeño campo de visión central.');
INSERT INTO visual_field_defect (code, name, description) VALUES ('hemianopia_homonymous_left', 'Hemianopsia homónima izquierda', 'Una condición donde la mitad izquierda del campo visual se pierde en ambos ojos.');
INSERT INTO visual_field_defect (code, name, description) VALUES ('hemianopia_homonymous_right', 'Hemianopsia homónima derecha', 'Una condición donde la mitad derecha del campo visual se pierde en ambos ojos.');
INSERT INTO visual_field_defect (code, name, description) VALUES ('hemianopia_heteronymous_binasal', 'Hemianopsia binasal', 'Una condición en la que falta la visión en la mitad interna del campo visual derecho e izquierdo.');
INSERT INTO visual_field_defect (code, name, description) VALUES ('hemianopia_heteronymous_bitemporal', 'Hemianopsia bitemporal', 'Una condición en la que falta la visión en la mitad exterior del campo visual derecho e izquierdo.');

-- INSERT INTO task
-- <a href="https://www.freepik.es/foto-gratis/puente-cable-murom-traves-oka_1469557.htm#page=2&query=bridge&position=0&from_view=search&track=sph">Imagen de bearfotos</a> en Freepik
INSERT INTO task (task_order, name, description, long_description, keywords, thumbnail_url, thumbnail_alt, coming_soon) VALUES (1, 'Journey to the Mangroves', 'Únete a un viaje virtual al Parque Isla Salamanca, mientras aprendes frases básicas en inglés relacionadas con los viajes y la naturaleza.', '¡Prepárate para un divertido viaje desde Barranquilla hasta el Parque Isla Salamanca! Cruzaremos un gran puente y el mar, mientras aprendemos a decir hola, adiós y gracias en inglés. También aprenderá nuevas palabras y frases relacionadas con los viajes y la naturaleza, como "barco", "playa", "montaña" y "árbol". ¿Estás emocionado?', '{ "travel", "nature", "vocabulary", "phrases", "basic English", "bridge", "sea" }', 'https://img.freepik.com/foto-gratis/puente-cable-murom-traves-oka_1398-3511.jpg', 'Imagen de la task', FALSE);
-- <a href="https://www.freepik.es/foto-gratis/ancho-rio-cerca-rio-negro-jamaica-paisaje-exotico-manglares_14875432.htm#query=mangrove%20swamp&position=33&from_view=search&track=ais">Imagen de mb-photoarts</a> en Freepik
INSERT INTO task (task_order, name, description, long_description, keywords, thumbnail_url, thumbnail_alt, coming_soon) VALUES (2, 'Meet the Animals', 'Explora la vida silvestre de los manglares, aprendiendo nombres de animales, hábitos y hábitats.', '¡Exploremos la increíble vida salvaje de los manglares! Conoceremos diferentes animales, como pájaros, cangrejos y reptiles, y aprenderemos a decir sus nombres y dónde viven. También aprenderemos algunos datos interesantes sobre sus hábitos y cómo sobreviven en los manglares. ¡Prepárate para divertirte y aprender cosas nuevas!', '{ "wildlife", "animals", "names", "habits", "habitats", "birds", "crabs", "reptiles" }', 'https://img.freepik.com/foto-gratis/ancho-rio-cerca-rio-negro-jamaica-paisaje-exotico-manglares_333098-202.jpg', 'Imagen de la task', FALSE);
-- Foto de Tom Fisk: https://www.pexels.com/es-es/foto/arboles-verdes-2666806/
INSERT INTO task (task_order, name, description, long_description, keywords, thumbnail_url, thumbnail_alt, coming_soon) VALUES (3, 'Eco Adventures', 'Embárcate en aventuras ecológicas, como caminatas, kayak y pesca, mientras practicas frases en inglés relacionadas con actividades al aire libre y conciencia ambiental.', '¡Es hora de algunas aventuras ecológicas en los manglares! Haremos senderismo, kayak y pesca, mientras aprendemos nuevas frases en inglés relacionadas con actividades al aire libre, como "¡vamos!", "Me estoy divirtiendo" y "esto es hermoso". También aprenderemos cómo cuidar el medio ambiente y por qué es importante proteger los manglares. ¿Estás preparado para el reto?', '{ "eco-friendly", "adventures", "hiking", "kayaking", "fishing", "phrases", "outdoor activities", "environmental awareness" }', 'https://images.pexels.com/photos/2666806/pexels-photo-2666806.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Imagen de la task', TRUE);
-- Foto de icon0.com: https://www.pexels.com/es-es/foto/madera-paisaje-naturaleza-verano-726298/
INSERT INTO task (task_order, name, description, long_description, keywords, thumbnail_url, thumbnail_alt, coming_soon) VALUES (4, 'Local Culture', 'Descubre la cultura local y las tradiciones de las comunidades que rodean el Parque Isla Salamanca, aprendiendo sobre comida, música, danza y artesanía.', '¡Descubramos la cultura local y las tradiciones de las comunidades que rodean el Parque Isla Salamanca! Aprenderemos a decir hola y cómo estás en inglés, y también aprenderemos sobre la deliciosa comida, la música divertida, el baile colorido y las hermosas artesanías que hacen que este lugar sea especial. ¡Incluso podrás practicar algunas expresiones en inglés y tener una conversación virtual con un amigo local!', '{ "local culture", "traditions", "food", "music", "dance", "crafts", "greetings", "expressions", "social interaction" }', 'https://images.pexels.com/photos/726298/pexels-photo-726298.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Imagen de la task', TRUE);
-- Foto de Marcel Kodama: https://www.pexels.com/es-es/foto/bosque-de-bambu-con-hilera-de-arboles-en-un-dia-soleado-3632689/
INSERT INTO task (task_order, name, description, long_description, keywords, thumbnail_url, thumbnail_alt, coming_soon) VALUES (5, 'The Great Challenge', 'Usa todo tu dominio del inglés para resolver un misterio o completar un rompecabezas relacionado con los manglares, consolidando tu aprendizaje y divirtiéndote.', '¿Estás listo para el último desafío? En esta tarea final, deberás usar todas tus habilidades en inglés para resolver un misterio o completar un rompecabezas relacionado con la historia, geografía y ecología de los manglares. Te divertirás y aprenderás al mismo tiempo, mientras consolidas todos los conocimientos adquiridos durante las tareas anteriores. ¿Tienes lo que se necesita para ser un gran estudiante de inglés?', '{ "English skills", "mystery", "puzzle", "mangroves", "learning", "fun" }', 'https://images.pexels.com/photos/3632689/pexels-photo-3632689.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1', 'Imagen de la task', TRUE);

DO $$
DECLARE
    last_question_id INTEGER;
BEGIN
    -- INSERT INTO question and option
    -- square brackets: prepositions; curly braces: nouns
    -- questions from task 1

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (2, 1, 'Are you [on|sobre] the {bridge|puente}?', NULL, NULL, 'select', 'Imagen de personas sobre un puente', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/bridge_1_qnqbxb', NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, we are', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, we aren''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, we aren''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, we are', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there is', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (2, 2, 'Is there a {river|río} [under|debajo] the {bridge|puente}?', NULL, NULL, 'select', 'Imagen de un río bajo un puente', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/river_bridge_1_bna92f', NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there is', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there aren''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, we are', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, she isn''t', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (2, 3, 'Look at the {road|camino}. Is there a {town|pueblo} [near|cerca de] it?', NULL, NULL, 'select', 'Imagen de un pueblo cerca de un camino', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/town_road_1_xa580z', NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Palermo town is near the road', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Tasajera town is behind the road', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Palermo town is on the bridge', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Tasajera town is under the river', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Palermo town is near Bogotá', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Tasajera town isn''t near Palermo', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (2, 4, 'Where is Laureano Gomez {toll|peaje}?', NULL, NULL, 'select', 'Imagen de un peaje entre un hotel y una granja', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/toll_1_ytula9', NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'It is between the hotel and Terranova farm', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'It is between the beach and the river', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'It is between the toll and the road', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'It is between the bridge and the river', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'It is between the beach and the road', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'It is between the hotel and the beach', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (2, 5, 'Is Playa Linda {beach|playa} [far from|lejos de] Barranquilla?', NULL, NULL, 'select', 'Imagen de una playa lejos de Barranquilla', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/beach_2_fixrlj', NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, it is', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, it isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, it isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, it is', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, he is', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there isn''t', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (2, 6, 'Are there {swamps|pantanos} [near|cerca de] the {beach|playa}?', NULL, NULL, 'select', 'Imagen de una playa con pantanos cerca', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/beach_swamps_1_qgvqm0', NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there are', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there aren''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there are', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there is', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (2, 7, 'Is there a {farm|granja} [next to|junto a] Salamanca Island?', NULL, NULL, 'select', 'Imagen de una granja cerca de Isla Salamanca', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/farm_1_x6oqzz', NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there is', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there are', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there aren''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there aren''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there is', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (3, 1, 'What was a part of the road?', NULL, NULL, 'select', NULL, NULL, NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'The bridge', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'The tunnel', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (3, 2, 'How do you thank someone?', NULL, NULL, 'select', NULL, NULL, NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Thank you', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Goodbye', 'Incorrect', FALSE);
    
    -- questions from task 2
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 1, 'Describe la imagen', NULL, NULL, 'select', 'Imagen de un manglar', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/mangrove_1_qiywjs', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Mangrove', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Beach', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Farm', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 2, 'Describe la imagen', NULL, NULL, 'select', 'Imagen de un pantano', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/swamp_1_zwechu', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Swamp', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Road', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Toll', 'Incorrect', FALSE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 3, 'Describe la imagen', NULL, NULL, 'select', 'Imagen de un camino', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/road_1_mmo3y3', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Road', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Swamp', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Toll', 'Incorrect', FALSE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 4, 'Describe la imagen', NULL, NULL, 'select', 'Imagen de una playa', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/beach_2_fixrlj', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Beach', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Mangrove', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Swamp', 'Incorrect', FALSE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 5, 'Describe la imagen', NULL, NULL, 'select', 'Imagen de un peaje', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/toll_1_ytula9', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Toll', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Natural park', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'River', 'Incorrect', FALSE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 6, 'Describe la imagen', NULL, NULL, 'select', 'Imagen de una granja', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/farm_1_x6oqzz', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Farm', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'River', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Road', 'Incorrect', FALSE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 7, 'Describe la imagen', NULL, NULL, 'flashcard', 'Imagen de un pueblo', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/town_road_1_xa580z', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Town', 'Town es pueblo en inglés', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Farm', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Natural park', 'Incorrect', FALSE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 8, 'Describe la imagen', NULL, NULL, 'flashcard', 'Imagen de un parque natural', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/natural_park_1_xpxbmi', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Natural park', 'Natural park es parque natural en inglés', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Hotel', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Beach', 'Incorrect', FALSE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 9, 'Describe la imagen', NULL, NULL, 'flashcard', 'Imagen de un puente', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/bridge_1_qnqbxb', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Bridge', 'Bridge es puente en inglés', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Mangrove', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Toll', 'Incorrect', FALSE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 10, 'Describe la imagen', NULL, NULL, 'flashcard', 'Imagen de un río', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/river_1_m0euyo', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'River', 'River es río en inglés', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Hotel', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Swamp', 'Incorrect', FALSE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 11, 'Describe la imagen', NULL, NULL, 'flashcard', 'Imagen de un hotel', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/hotel_1_kd2kmr', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Hotel', 'Hotel es hotel en inglés', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Town', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Toll', 'Incorrect', FALSE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 12, '¿Estás en el puente?', NULL, NULL, 'order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Are you on the bridge?', 'Correct', TRUE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 13, '¿Hay un río bajo el puente?', NULL, NULL, 'order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Is there a river under the bridge?', 'Correct', TRUE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 14, '¿Hay un pueblo cerca del camino?', NULL, NULL, 'order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Is there a town near the road?', 'Correct', TRUE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 15, '¿La playa está detrás del hotel?', NULL, NULL, 'order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Is the beach behind the hotel?', 'Correct', TRUE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 16, '¿Está el peaje entre la granja y el pantano?', NULL, NULL, 'order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Is the toll between the farm and the swamp?', 'Correct', TRUE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 17, '¿Está el parque natural lejos del pueblo?', NULL, NULL, 'order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Is the natural park far from the town?', 'Correct', TRUE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 18, '¿Hay una granja al lado del parque natural?', NULL, NULL, 'order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Is there a farm next to the natural park?', 'Correct', TRUE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 19, '¿Hay un puente sobre el pantano?', NULL, NULL, 'order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Is there a bridge over the swamp?', 'Correct', TRUE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 20, 'The cat is _ the box', NULL, NULL, 'fill', 'Imagen de un gato detrás de una caja', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/behind_1_wj53ay', 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'behind', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'near', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'under', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 21, 'The lion is _ the sofa', NULL, NULL, 'fill', 'Imagen de un león lejos de un sofá', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/far_from_1_mu3izv', 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'far from', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'next to', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'close to', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 22, 'The bird is _ the box', NULL, NULL, 'fill', 'Imagen de un ave en frente de una caja', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/in_front_of_1_xc38ie', 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'in front of', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'behind', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'under', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 23, 'The lion is _ the sofa', NULL, NULL, 'fill', 'Imagen de un león cerca de un sofá', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/near_to_1_fox6gs', 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'near', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'over', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'in front of', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 24, 'The apple is _ the box', NULL, NULL, 'fill', 'Imagen de una manzana encima de una caja', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/on_1_d2imgf', 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'on', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'under', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'in', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 25, 'The plane is _ the city', NULL, NULL, 'fill', 'Imagen de una avión sobre una ciudad', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/over_1_zjvecs', 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'over', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'on', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'behind', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 26, 'The dog is _ the table', NULL, NULL, 'fill', 'Imagen de un perro debajo de una mesa', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/under_1_w31fsl', 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'under', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'over', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'in', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 27, 'The cat is _ the box', NULL, NULL, 'fill', 'Imagen de un gato al lado de una caja', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/next_to_1_vjpmjz', 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'next to', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'over', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'far from', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 28, 'The cat is _ the tables', NULL, NULL, 'fill', 'Imagen de un gato entre dos mesas', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/between_1_owmath', 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'between', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'over', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'far from', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 29, 'Are you on the bridge?', NULL, NULL, 'audio_order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Are you on the bridge?', 'Correct', TRUE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 30, 'Is there a river under the bridge?', NULL, NULL, 'audio_order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Is there a river under the bridge?', 'Correct', TRUE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 31, 'Is there a town near the road?', NULL, NULL, 'audio_order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Is there a town near the road?', 'Correct', TRUE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 32, 'Is the beach behind the hotel?', NULL, NULL, 'audio_order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Is the beach behind the hotel?', 'Correct', TRUE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 33, 'Is the toll between the farm and the swamp?', NULL, NULL, 'audio_order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Is the toll between the farm and the swamp?', 'Correct', TRUE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 34, 'Is the natural park far from the town?', NULL, NULL, 'audio_order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Is the natural park far from the town?', 'Correct', TRUE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 35, 'Is there a farm next to the natural park?', NULL, NULL, 'audio_order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Is there a farm next to the natural park?', 'Correct', TRUE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 36, 'Is there a bridge over the swamp?', NULL, NULL, 'audio_order', NULL, NULL, 'prepositions') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Is there a bridge over the swamp?', 'Correct', TRUE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 37, 'Mangrove', NULL, NULL, 'audio_select', 'Imagen de un manglar', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/mangrove_1_qiywjs', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Mangrove', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Beach', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Farm', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 38, 'Swamp', NULL, NULL, 'audio_select', 'Imagen de un pantano', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/swamp_1_zwechu', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Swamp', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Road', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Toll', 'Incorrect', FALSE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 39, 'Road', NULL, NULL, 'audio_select', 'Imagen de un camino', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/road_1_mmo3y3', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Road', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Swamp', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Toll', 'Incorrect', FALSE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 40, 'Beach', NULL, NULL, 'audio_select', 'Imagen de una playa', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/beach_2_fixrlj', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Beach', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Mangrove', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Swamp', 'Incorrect', FALSE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 41, 'Toll', NULL, NULL, 'audio_select', 'Imagen de un peaje', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/toll_1_ytula9', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Toll', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Natural park', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'River', 'Incorrect', FALSE);
    
    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 42, 'Farm', NULL, NULL, 'audio_select', 'Imagen de una granja', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/farm_1_x6oqzz', 'vocabulary') RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Farm', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'River', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Road', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 43, 'The cat is behind the box', NULL, NULL, 'audio_speaking', 'Imagen de un gato detrás de una caja', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/behind_1_wj53ay', 'prepositions') RETURNING id_question INTO last_question_id;

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 44, 'The lion is far from the sofa', NULL, NULL, 'audio_speaking', 'Imagen de un león lejos de un sofá', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/far_from_1_mu3izv', 'prepositions') RETURNING id_question INTO last_question_id;

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 45, 'The bird is in front of the box', NULL, NULL, 'audio_speaking', 'Imagen de un ave en frente de una caja', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/in_front_of_1_xc38ie', 'prepositions') RETURNING id_question INTO last_question_id;

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 46, 'The lion is near the sofa', NULL, NULL, 'audio_speaking', 'Imagen de un león cerca de un sofá', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/near_to_1_fox6gs', 'prepositions') RETURNING id_question INTO last_question_id;

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 47, 'The apple is on the box', NULL, NULL, 'audio_speaking', 'Imagen de una manzana encima de una caja', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/on_1_d2imgf', 'prepositions') RETURNING id_question INTO last_question_id;

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 48, 'The plane is over the city', NULL, NULL, 'audio_speaking', 'Imagen de una avión sobre una ciudad', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/over_1_zjvecs', 'prepositions') RETURNING id_question INTO last_question_id;

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 49, 'The dog is under the table', NULL, NULL, 'audio_speaking', 'Imagen de un perro debajo de una mesa', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/under_1_w31fsl', 'prepositions') RETURNING id_question INTO last_question_id;

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 50, 'The cat is next to the box', NULL, NULL, 'audio_speaking', 'Imagen de un gato al lado de una caja', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/next_to_1_vjpmjz', 'prepositions') RETURNING id_question INTO last_question_id;

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (4, 51, 'The cat is between the tables', NULL, NULL, 'audio_speaking', 'Imagen de un gato entre dos mesas', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/between_1_owmath', 'prepositions') RETURNING id_question INTO last_question_id;

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (5, 1, 'Are you [on|sobre] the {bridge|puente}?', NULL, NULL, 'select', 'Imagen de personas sobre un puente', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/bridge_1_qnqbxb', NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, we are', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, we aren''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, we aren''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, we are', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there is', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (5, 2, 'Is there a {river|río} [under|debajo] the {bridge|puente}?', NULL, NULL, 'select', 'Imagen de un río bajo un puente', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/river_bridge_1_bna92f', NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there is', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there aren''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, we are', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, she isn''t', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (5, 3, 'Look at the {road|camino}. Is there a {town|pueblo} [near|cerca de] it?', NULL, NULL, 'select', 'Imagen de un pueblo cerca de un camino', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/town_road_1_xa580z', NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Palermo town is near the road', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Tasajera town is behind the road', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Palermo town is on the bridge', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Tasajera town is under the river', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Palermo town is near Bogotá', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Tasajera town isn''t near Palermo', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (5, 4, 'Where is Laureano Gomez {toll|peaje}?', NULL, NULL, 'select', 'Imagen de un peaje entre un hotel y una granja', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/toll_1_ytula9', NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'It is between the hotel and Terranova farm', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'It is between the beach and the river', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'It is between the toll and the road', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'It is between the bridge and the river', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'It is between the beach and the road', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'It is between the hotel and the beach', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (5, 5, 'Is Playa Linda {beach|playa} [far from|lejos de] Barranquilla?', NULL, NULL, 'select', 'Imagen de una playa lejos de Barranquilla', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/beach_2_fixrlj', NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, it is', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, it isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, it isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, it is', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, he is', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there isn''t', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (5, 6, 'Are there {swamps|pantanos} [near|cerca de] the {beach|playa}?', NULL, NULL, 'select', 'Imagen de una playa con pantanos cerca', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/beach_swamps_1_qgvqm0', NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there are', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there aren''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there are', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there is', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (5, 7, 'Is there a {farm|granja} [next to|junto a] Salamanca Island?', NULL, NULL, 'select', 'Imagen de una granja cerca de Isla Salamanca', 'https://res.cloudinary.com/dajnynv13/image/upload/eyeland/task_1/farm_1_x6oqzz', NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there is', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there isn''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there are', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there aren''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Yes, there aren''t', 'Incorrect', FALSE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'No, there is', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (6, 1, 'What was a part of the road?', NULL, NULL, 'select', NULL, NULL, NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'The bridge', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'The tunnel', 'Incorrect', FALSE);

    INSERT INTO question (id_task_stage, question_order, content, audio_url, video_url, type, img_alt, img_url, topic) VALUES (6, 2, 'How do you thank someone?', NULL, NULL, 'select', NULL, NULL, NULL) RETURNING id_question INTO last_question_id;
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Thank you', 'Correct', TRUE);
    INSERT INTO option (id_question, content, feedback, correct) VALUES (last_question_id, 'Goodbye', 'Incorrect', FALSE);
END $$;

-- *INSERTANDO USUARIOS E INSTITUCIONES DE PRUEBA
-- INSERT INTO institution
INSERT INTO institution (name, nit, address, city, country, phone_code, phone_number, email, website_url) VALUES ('Institución 1', '123456789', 'Cra 45 # 23-67', 'Barranquilla', 'Colombia', '57', '3011231234', 'ied1@test.com', 'https://media.tenor.com/x8v1oNUOmg4AAAAd/rickroll-roll.gif');

-- INSERT INTO teacher
INSERT INTO teacher (id_institution, username, password, first_name, last_name, email, phone_code, phone_number) VALUES (1, 'teacher', 'teacher', 'Profesor', 'Prueba', 'teacher1@test.com', '57', '3011231234');
INSERT INTO teacher (id_institution, username, password, first_name, last_name, email, phone_code, phone_number) VALUES (1, 'teacher2', 'teacher2', 'Profesor', 'Prueba', 'teacher2@test.com', '57', '3011231234');
INSERT INTO teacher (id_institution, username, password, first_name, last_name, email, phone_code, phone_number) VALUES (1, 'teacher3', 'teacher3', 'Profesor', 'Prueba', 'teacher3@test.com', '57', '3011231234');

-- INSERT INTO course
INSERT INTO course (id_institution, id_teacher, name) VALUES (1, 1, 'Curso 1');
INSERT INTO course (id_institution, id_teacher, name) VALUES (1, 1, 'Curso 2');
INSERT INTO course (id_institution, id_teacher, name) VALUES (1, 2, 'Curso 1');
INSERT INTO course (id_institution, id_teacher, name) VALUES (1, 3, 'Curso 1');

-- INSERT INTO student
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (1, 'Estudiante1', 'Apellido', 'student1', 'pass123', 'student1@test.com', '57', '3001231234', 1, 1, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (1, 'Estudiante2', 'Apellido', 'student2', 'pass123', 'student2@test.com', '57', '3001231234', 2, 1, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (1, 'Estudiante3', 'Apellido', 'student3', 'pass123', 'student3@test.com', '57', '3001231234', 3, 1, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (1, 'Estudiante4', 'Apellido', 'student4', 'pass123', 'student4@test.com', '57', '3001231234', 4, 1, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (1, 'Estudiante5', 'Apellido', 'student5', 'pass123', 'student5@test.com', '57', '3001231234', 5, 1, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (1, 'Estudiante6', 'Apellido', 'student6', 'pass123', 'student6@test.com', '57', '3001231234', 6, 1, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (1, 'Estudiante7', 'Apellido', 'student7', 'pass123', 'student7@test.com', '57', '3001231234', 7, 1, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (2, 'Estudiante1', 'Apellido', 'student21', 'pass123', 'student21@test.com', '57', '3001231234', 1, 1, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (2, 'Estudiante2', 'Apellido', 'student22', 'pass123', 'student22@test.com', '57', '3001231234', 1, 2, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (2, 'Estudiante3', 'Apellido', 'student23', 'pass123', 'student23@test.com', '57', '3001231234', 1, 3, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (2, 'Estudiante4', 'Apellido', 'student24', 'pass123', 'student24@test.com', '57', '3001231234', 1, 4, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (2, 'Estudiante5', 'Apellido', 'student25', 'pass123', 'student25@test.com', '57', '3001231234', 1, 5, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (2, 'Estudiante6', 'Apellido', 'student26', 'pass123', 'student26@test.com', '57', '3001231234', 1, 6, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (2, 'Estudiante7', 'Apellido', 'student27', 'pass123', 'student27@test.com', '57', '3001231234', 1, 7, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (2, 'Estudiante7', 'Apellido', 'student28', 'pass123', 'student28@test.com', '57', '3001231234', 1, 8, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (3, 'Estudiante1', 'Apellido', 'student31', 'pass123', 'student31@test.com', '57', '3001231234', 1, 1, 1);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (3, 'Estudiante2', 'Apellido', 'student32', 'pass123', 'student32@test.com', '57', '3001231234', 1, 1, 2);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (3, 'Estudiante3', 'Apellido', 'student33', 'pass123', 'student33@test.com', '57', '3001231234', 1, 1, 3);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (3, 'Estudiante4', 'Apellido', 'student34', 'pass123', 'student34@test.com', '57', '3001231234', 1, 1, 4);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (3, 'Estudiante5', 'Apellido', 'student35', 'pass123', 'student35@test.com', '57', '3001231234', 1, 1, 5);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (3, 'Estudiante6', 'Apellido', 'student36', 'pass123', 'student36@test.com', '57', '3001231234', 1, 1, 6);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (3, 'Estudiante7', 'Apellido', 'student37', 'pass123', 'student37@test.com', '57', '3001231234', 1, 1, 7);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (3, 'Estudiante7', 'Apellido', 'student38', 'pass123', 'student38@test.com', '57', '3001231234', 1, 1, 8);
INSERT INTO student (id_course, first_name, last_name, username, password, email, phone_code, phone_number, id_blindness_acuity, id_visual_field_defect, id_color_deficiency) VALUES (3, 'Estudiante7', 'Apellido', 'student39', 'pass123', 'student39@test.com', '57', '3001231234', 1, 1, 9);

-- INSERT INTO team
INSERT INTO team (id_course, name, code) VALUES (1, 'Equipo 1', '111111');
INSERT INTO team (id_course, name, code) VALUES (1, 'Equipo 2', '222222');
INSERT INTO team (id_course, name, code) VALUES (1, 'Equipo 3', '333333');
INSERT INTO team (id_course, name, code) VALUES (2, 'Equipo 4', '444444');
INSERT INTO team (id_course, name, code) VALUES (2, 'Equipo 5', '555555');
INSERT INTO team (id_course, name, code) VALUES (2, 'Equipo 6', '666666');
INSERT INTO team (id_course, name, code) VALUES (3, 'Equipo 7', '777777');
INSERT INTO team (id_course, name, code) VALUES (3, 'Equipo 8', '888888');
INSERT INTO team (id_course, name, code) VALUES (3, 'Equipo 9', '999999');

-- INSERT INTO admin
INSERT INTO admin (first_name, last_name, email, username, password) VALUES ('Brunner', 'Hurtador', 'carlbrunner@hurtador.com', 'brunner', 'cocacola');

-- INSERT INTO release
INSERT INTO release (url, version) VALUES ('https://storage.googleapis.com/eyeland-0/app/dist/v/eyeland-3.5.apk', '3.5');
INSERT INTO release (url, version) VALUES ('https://storage.googleapis.com/eyeland-0/app/dist/v/eyeland-3.6.apk', '3.6');

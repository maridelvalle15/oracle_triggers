DROP TABLE DEPARTAMENTO CASCADE CONSTRAINTS;
DROP TABLE JEFE CASCADE CONSTRAINTS;
DROP TYPE Departamento_T force;
DROP TYPE JEFE_T force;
DROP TRIGGER delete_jefe;
DROP TRIGGER delete_departamento;
DROP TRIGGER insert_departamento;
DROP TRIGGER insert_jefe;
DROP TRIGGER update_departamento;
DROP TRIGGER update_jefe;

CREATE OR REPLACE TYPE Jefe_T;
/

CREATE OR REPLACE TYPE Departamento_T;
/

CREATE OR REPLACE TYPE Departamento_T AS OBJECT
	(nombre VARCHAR2(40),
	jefe_dep REF Jefe_T);
/

CREATE OR REPLACE TYPE Jefe_T AS OBJECT
	(cedula CHAR(10),
	nombre VARCHAR2(20),
	apellido VARCHAR2(20),
	dep REF Departamento_T);
/

CREATE TABLE DEPARTAMENTO OF Departamento_T
    (PRIMARY KEY (nombre));   

CREATE TABLE Jefe OF Jefe_T 
	(PRIMARY KEY (cedula),
	foreign key (dep) references Departamento);
    

ALTER TABLE Departamento
	ADD FOREIGN KEY (jefe_dep) references Jefe;


----------------------TRIGGERS----------------------

--DELETE JEFE

CREATE OR REPLACE TRIGGER delete_jefe
    AFTER DELETE ON Jefe FOR EACH ROW
    WHEN (OLD.dep IS NOT NULL)
    BEGIN
        UPDATE Departamento d
        SET d.jefe_dep = NULL
        WHERE REF(d) = :OLD.dep;
    END;
/


--DELETE DEPARTAMENTO
CREATE OR REPLACE TRIGGER delete_departamento
    AFTER DELETE ON departamento FOR EACH ROW
    WHEN (OLD.jefe_dep IS NOT NULL)
    BEGIN
        UPDATE Jefe j
        SET j.dep= NULL
        WHERE REF(j) = :OLD.jefe_dep;
    END;
/

--INSERT DEPARTAMENTO

CREATE OR REPLACE TRIGGER insert_departamento
    BEFORE INSERT ON Departamento FOR EACH ROW
    WHEN (OLD.jefe_dep IS NULL)
    DECLARE
        jefes NUMBER;
    BEGIN   
            SELECT COUNT(*) into jefes FROM Jefe j WHERE REF(j) = :NEW.jefe_dep and j.dep IS NOT NULL;
        IF ( jefes > 0 ) THEN
            RAISE_APPLICATION_ERROR(-20500, 'Un jefe no puede estar asignado'
            ||' a dos departamentos.');
        END IF;
    END; 
/

--INSERT JEFE

CREATE OR REPLACE TRIGGER insert_jefe
    BEFORE INSERT ON Jefe FOR EACH ROW
    WHEN (OLD.dep IS NULL)
    DECLARE
        deps NUMBER;
    BEGIN         
        SELECT COUNT(*) into deps FROM Departamento d WHERE REF(d) = :NEW.dep and d.jefe_dep IS NOT NULL;
        IF ( deps > 0 ) THEN
            RAISE_APPLICATION_ERROR(-20500, 'Un departamento no puede tener'
            ||' dos jefes asignados.');
        END IF;
    END; 
/

--UPDATE
/*
CREATE OR REPLACE TRIGGER update_jefe
    BEFORE UPDATE OF dep ON Jefe FOR EACH ROW
    DECLARE
        departamentos NUMBER;
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        IF (:OLD.dep IS NULL) THEN
            SELECT COUNT(*) into departamentos FROM Departamento d WHERE REF(d) = :NEW.dep and d.jefe_dep IS NOT NULL;
            IF ( departamentos > 0 ) THEN
                RAISE_APPLICATION_ERROR(-20500, 'Un departamento no puede tener'
                ||' a dos jefes asignados.');
            END IF;
        ELSE
            :OLD.dep := NULL;

            UPDATE Jefe j
                SET j.dep = NULL WHERE j.dep = :NEW.dep;

            UPDATE Departamento d
                SET d.jefe_dep = NULL
                WHERE REF(d) = :OLD.dep;

            UPDATE Departamento d
                SET d.jefe_dep= NULL 
                WHERE REF(d) = :NEW.dep;

            UPDATE Departamento d
                SET d.jefe_dep = MAKE_REF(Jefe, :new.object_id)
                WHERE REF(d) = :NEW.dep;

            UPDATE Jefe j 
                SET j.dep = :NEW.dep
                WHERE REF(j) = MAKE_REF(Jefe, :new.object_id);

        END IF;
        commit;
    END; 
/
*/
CREATE OR REPLACE TRIGGER update_departamento
    BEFORE UPDATE OF jefe_dep ON Departamento FOR EACH ROW
    DECLARE
        jefes NUMBER;
        dep_viejo Jefe.dep%TYPE;
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        IF (:OLD.jefe_dep IS NULL) THEN
            SELECT COUNT(*) into jefes FROM Jefe j WHERE REF(j) = :NEW.jefe_dep and j.dep IS NOT NULL;
            IF ( jefes > 0 ) THEN
                RAISE_APPLICATION_ERROR(-20500, 'Un jefe no puede estar asignado'
                ||' a dos departamentos.');
            END IF;
        ELSE
            dbms_output.put_line('hola');

            :NEW.jefe_dep := NULL;
            UPDATE Departamento d 
            SET :NEW.jefe_dep = d.jefe_dep
            WHERE :NEW.nombre = d.nombre;
            /*
            UPDATE Departamento d
                SET d.jefe_dep = NULL WHERE d.jefe_dep = :OLD.jefe_dep;
            
            UPDATE Departamento d
                SET d.jefe_dep = NULL WHERE d.jefe_dep = :NEW.jefe_dep;
            *//*
            UPDATE Jefe j 
                SET j.dep = NULL
                WHERE REF(j) = :OLD.jefe_dep;
            /*
            UPDATE Jefe j 
                SET j.dep = NULL 
                WHERE REF(j) = :NEW.jefe_dep;
            /*
            UPDATE Jefe j
                SET j.dep = MAKE_REF(Departamento, :new.object_id)
                WHERE REF(j) = :NEW.jefe_dep;
            /*
            UPDATE Departamento d 
                SET d.jefe_dep = :NEW.jefe_dep
                WHERE REF(d) = MAKE_REF(Departamento, :new.object_id);
            */
        END IF;
        commit;
    END; 
/


----
INSERT INTO Jefe VALUES
    ('V-6544230','Carlos','Rodriguez',NULL);
INSERT INTO Jefe VALUES
    ('V-18765234','Maria','Gomez',NULL);
INSERT INTO Jefe VALUES
    ('E-13455892','Pedro','Perez',NULL);

    INSERT INTO Departamento
        SELECT 'Departamento 1', 
                REF(j)
        FROM Jefe j WHERE j.cedula = 'V-6544230';

INSERT INTO Departamento
    SELECT 'Departamento 2', 
            REF(j)
    FROM Jefe j WHERE j.cedula = 'V-18765234';

INSERT INTO Departamento
    SELECT 'Departamento 3', 
            REF(j)
    FROM Jefe j WHERE j.cedula = 'E-13455892';

/*      Actualizamos los jefes para indicar de que departamento son jefes       */
UPDATE Jefe SET dep = (SELECT REF(d) FROM Departamento d WHERE d.nombre='Departamento 1') WHERE cedula='V-6544230';
UPDATE Jefe SET dep = (SELECT REF(d) FROM Departamento d WHERE d.nombre='Departamento 2') WHERE cedula='V-18765234';
UPDATE Jefe SET dep = (SELECT REF(d) FROM Departamento d WHERE d.nombre='Departamento 3') WHERE cedula='E-13455892';


----
UPDATE Departamento SET jefe_dep = (SELECT REF(j) FROM Jefe j WHERE j.cedula = 'V-18765234') WHERE nombre='Departamento 1';

select * from jefe;

select deref(d.dep) from jefe d where d.cedula='V-18765234';
select deref(d.jefe_dep) from departamento d where d.nombre='Departamento 1';
select deref(d.dep) from jefe d where d.cedula='V-6544230';
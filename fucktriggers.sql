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
DROP PROCEDURE update_dep_procedure;
DROP PROCEDURE update_jefe_procedure;

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
/* Coloca en NULL la referencia colgante del departamento correspondiente */
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
/* Coloca en NULL la referencia colgante del jefe correspondiente */
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
/* Verificamos que se inserta en un departamento el jefe que le corresponde en la relacion 1:1 */
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
/* Verificamos que se inserta en un jefe el departamento que le corresponde en la relacion 1:1 */
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

-- PROCEDIMIENTO PARA LLAMAR EN EL TRIGGER UPDATE DEPARTAMENTO
    /* Actualiza a NULL la referencia a jefe en el departamento correspondiente */

CREATE PROCEDURE update_dep_procedure (departamento Jefe.dep%TYPE) AS
   BEGIN
      UPDATE Departamento d
      SET jefe_dep = NULL
      WHERE REF(d) = departamento;
      exception 
        when no_data_found 
        then raise_application_error(-20500,'Error en el procedimiento, DATA NOT FOUND');
   END;
/

-- UPDATE DEPARTAMENTO

CREATE OR REPLACE TRIGGER update_departamento
    BEFORE UPDATE OF jefe_dep ON Departamento FOR EACH ROW
    DECLARE
        jefes NUMBER;
        dep_viejo Jefe.dep%TYPE;
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        /* Funciona como el insert. Cuando se hace update de una referencia a jefe en NULL verificamos que efectivamente
            le corresponde
         */
        IF (:OLD.jefe_dep IS NULL) THEN
            SELECT COUNT(*) into jefes FROM Jefe j WHERE REF(j) = :NEW.jefe_dep and j.dep.nombre = :OLD.nombre;
            IF (jefes = 0) THEN
                RAISE_APPLICATION_ERROR(-20500, 'Un jefe no puede estar asignado'
                ||' a dos departamentos.');
            END IF;
        /* En caso contrario, seteamos en NULL las referencias que sobran y seteamos las referencias nuevas */
        ELSE
            /*
                Estas dos lineas deberian obtener al departamento dej jefe anterior, para asignarle la referencia al
                jefe como NULL. Pero dan errores
            */
            /*
            SELECT j.dep INTO dep_viejo from Jefe j WHERE REF(j) = :OLD.jefe_dep and j.dep IS NOT NULL;

            update_dep_procedure(dep_viejo);
            */

            /*
                Estos updates colocan en NULL las referencias antiguas de los departamentos
            */
            UPDATE Jefe j
                SET j.dep = NULL 
                WHERE REF(j) = :NEW.jefe_dep;
            UPDATE Jefe j
                SET j.dep = NULL 
                WHERE REF(j) = :OLD.jefe_dep;
            /*
                Este update actualiza la nueva referencia del djefe con el nuevo departamento. Pero como no se puede setear
                la antigua referencia del departamento a NULL, da error (por la primera condicion del trigger update).
            */
            /*
            UPDATE Jefe j
                SET j.dep = MAKE_REF(Departamento, :new.object_id)
                WHERE REF(j) = :NEW.jefe_dep;
            */
        END IF;
        commit;
    END; 
/

-- PROCEDIMIENTO PARA LLAMAR EN EL TRIGGER UPDATE JEFE
    /* Actualiza a NULL la referencia a departamento en el jefe correspondiente */

CREATE PROCEDURE update_jefe_procedure (jefe Departamento.jefe_dep%TYPE) AS
   BEGIN
      UPDATE Jefe j
      SET dep = NULL
      WHERE REF(j) = jefe;
      exception 
        when no_data_found 
        then raise_application_error(-20500,'Error en el procedimiento, DATA NOT FOUND');
   END;
/

-- UPDATE JEFE

CREATE OR REPLACE TRIGGER update_jefe
    BEFORE UPDATE OF dep ON Jefe FOR EACH ROW
    DECLARE
        departamentos NUMBER;
        jefe_viejo Departamento.jefe_dep%TYPE;
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        /* Funciona como el insert. Cuando se hace update de una referencia a departamento en NULL verificamos que efectivamente
            le corresponde
         */
        IF (:OLD.dep IS NULL) THEN
            SELECT COUNT(*) into departamentos FROM Departamento d WHERE REF(d) = :NEW.dep and d.jefe_dep.cedula <> :OLD.cedula;
            IF (departamentos > 0) THEN
                RAISE_APPLICATION_ERROR(-20500, 'Un departamento no puede tener asignado'
                ||' dos jefes.');
            END IF;
        /* En caso contrario, seteamos en NULL las referencias que sobran y seteamos las referencias nuevas */
        ELSE

            /*
                Estas dos lineas deberian obtener al jefe del departamento anterior, para asignarle la referencia al
                departamento como NULL. Pero dan errores
            */
            /*
            SELECT d.jefe_dep INTO jefe_viejo from Departamento d WHERE REF(d) = :OLD.dep and d.jefe_dep IS NOT NULL;

            update_jefe_procedure(jefe_viejo);
            */

            /*
                Estos updates colocan en NULL las referencias antiguas de los departamentos
            */
            UPDATE Departamento d
                SET d.jefe_dep = NULL 
                WHERE REF(d) = :NEW.dep;
            UPDATE Departamento d
                SET d.jefe_dep = NULL 
                WHERE REF(d) = :OLD.dep;
            /*
                Este update actualiza la nueva referencia del departamento con el nuevo jefe. Pero como no se puede setear
                la antigua referencia del jefe a NULL, da error(por la primera condicion del trigger update).
            */
            /*
            UPDATE Departamento d
                SET d.jefe_dep = MAKE_REF(Jefe, :new.object_id)
                WHERE REF(d) = :NEW.dep;
            */

        END IF;
        commit;
    END; 
/
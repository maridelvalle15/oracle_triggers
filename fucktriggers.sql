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

-- UPDATE DEPARTAMENTO

CREATE OR REPLACE TRIGGER update_departamento
    BEFORE UPDATE OF jefe_dep ON Departamento FOR EACH ROW
    DECLARE
        jefes NUMBER;
        dep_viejo Jefe.dep%TYPE;
        dep Jefe.dep%TYPE;
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        IF (:OLD.jefe_dep IS NULL) THEN
            SELECT COUNT(*) into jefes FROM Jefe j WHERE REF(j) = :NEW.jefe_dep and j.dep.nombre = :OLD.nombre;
            IF (jefes = 0) THEN
                RAISE_APPLICATION_ERROR(-20500, 'Un jefe no puede estar asignado'
                ||' a dos departamentos.');
            END IF;
        END IF;
        commit;
    END; 
/
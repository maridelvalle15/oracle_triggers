/*****************************************
************** INSERCIONES ***************
*****************************************/
ALTER TRIGGER update_jefe DISABLE;
/* Inserciones correctas a la tabla jefe */
INSERT INTO Jefe VALUES
    ('V-6544230','Carlos','Rodriguez',NULL);
INSERT INTO Jefe VALUES
    ('V-18765234','Maria','Gomez',NULL);
INSERT INTO Jefe VALUES
    ('V-12765332','Pedro','Perez',NULL);
INSERT INTO Jefe VALUES
    ('V-12345677','Persona','X',NULL);

/* Inserciones correctas a la tabla departamento */
INSERT INTO Departamento VALUES
    ('Hola',NULL);

INSERT INTO Departamento VALUES
    ('Chao',NULL);

INSERT INTO Departamento VALUES
    ('Tres',NULL);

/* Inserciones correctas a la tabla jefe */
INSERT INTO Jefe 
    SELECT '222','Abuela','Abuelo', REF(d)
            From Departamento d where d.nombre='Hola';
INSERT INTO Jefe 
    SELECT '1111','Mama','Papa',REF(d)
            From Departamento d where d.nombre='Chao';


/* Inserciones correctas a la tabla departamento */
INSERT INTO Departamento
    SELECT 'Departamento 1', 
            REF(j)
    FROM Jefe j WHERE j.cedula = 'V-6544230';
INSERT INTO Departamento
    SELECT 'Departamento 2', 
            REF(j)
    FROM Jefe j WHERE j.cedula = 'V-18765234';
INSERT INTO Departamento
    SELECT 'Departamento X', 
            REF(j)
    FROM Jefe j WHERE j.cedula = 'V-12345677';

/*      Actualizamos los jefes para indiV-12345677car de que departamento son jefes       */
ALTER TRIGGER update_jefe ENABLE;

UPDATE Jefe SET dep = (SELECT REF(d) FROM Departamento d WHERE d.nombre='Departamento 1') WHERE cedula='V-6544230';
UPDATE Jefe SET dep = (SELECT REF(d) FROM Departamento d WHERE d.nombre='Departamento 2') WHERE cedula='V-18765234';
UPDATE Jefe SET dep = (SELECT REF(d) FROM Departamento d WHERE d.nombre='Departamento X') WHERE cedula='V-12345677';

/* Consultas para ver resultados */
select * from jefe;
select * from departamento;

/* Si intentamos actualizar a un jefe un departamento que ya tiene jefe, se dispara el trigger dando mensaje de error */
UPDATE Jefe SET dep = (SELECT REF(d) FROM Departamento d WHERE d.nombre='Departamento 2') WHERE cedula='V-12765332';

/* Actualizamos los departamentos para indicar quienes son sus jefes */
UPDATE Departamento SET jefe_dep = (SELECT REF(j) from Jefe j where j.cedula='222') WHERE nombre = 'Hola';
/* Si intentamos actualizar a un departamento un jefe que ya trabaja en un departamento, se dispara el trigger dando mensaje de error */
UPDATE Departamento SET jefe_dep = (SELECT REF(j) from Jefe j where j.cedula='222') WHERE nombre = 'Tres';

    

/* Si insertamos un jefe con un departamento en el que ya alguien trabaja, se dispara el trigger dando mensaje de error */
INSERT INTO Jefe 
    SELECT '333','Tia','Tio',REF(d)
            From Departamento d where d.nombre='Hola';

/* Si insertamos un departamento con un jefe que ya trabaja en un departamento, se dispara el trigger dando mensaje de error */
INSERT INTO Departamento
    SELECT 'Departamento 3', 
            REF(j)
    FROM Jefe j WHERE j.cedula = 'V-18765234';

/* Actualizamos un jefe que ya trabajaba en un departamento, a un departamento que ya tenia jefe. 
    Dispara el trigger y coloca en NULL la referencia a jefe en el Departamento anterior y el nuevo
    Esta linea no funciona si descomentamos el ELSE del trigger update_departamento. Da el error ORA-00060: deadlock detected while waiting for resource
 */
ALTER TRIGGER update_jefe ENABLE;
UPDATE Jefe SET dep = (SELECT REF(d) FROM Departamento d WHERE d.nombre='Departamento 1') WHERE cedula='V-18765234';
select * from departamento;

/* Activamos el trigger delete al eliminar un departamento. Se borra la referencia en el jefe correspondiente */
DELETE FROM Jefe where cedula='V-12345677';
select * from jefe;
select * from departamento;
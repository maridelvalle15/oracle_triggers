INSERT INTO Jefe VALUES
    ('V-6544230','Carlos','Rodriguez',NULL);
INSERT INTO Jefe VALUES
    ('V-18765234','Maria','Gomez',NULL);

INSERT INTO Departamento VALUES
    ('Hola',NULL);

INSERT INTO Departamento VALUES
    ('Chao',NULL);

INSERT INTO Jefe 
    SELECT '222','Abuela','Abuelo', REF(d)
            From Departamento d where d.nombre='Hola';
INSERT INTO Jefe 
    SELECT '1111','Mama','Papa',REF(d)
            From Departamento d where d.nombre='Chao';

INSERT INTO Departamento
    SELECT 'Departamento 1', 
            REF(j)
    FROM Jefe j WHERE j.cedula = 'V-6544230';
INSERT INTO Departamento
    SELECT 'Departamento 3', 
            REF(j)
    FROM Jefe j WHERE j.cedula = 'V-18765234';

/*      Actualizamos los jefes para indicar de que departamento son jefes       */
UPDATE Jefe SET dep = (SELECT REF(d) FROM Departamento d WHERE d.nombre='Departamento 1') WHERE cedula='V-6544230';
UPDATE Jefe SET dep = (SELECT REF(d) FROM Departamento d WHERE d.nombre='Departamento 2') WHERE cedula='V-18765234';

UPDATE Departamento SET jefe_dep = (SELECT REF(j) from Jefe j where j.cedula='222') WHERE nombre = 'Hola';
UPDATE Departamento SET jefe_dep = (SELECT REF(j) from Jefe j where j.cedula='222') WHERE nombre = 'Chao';



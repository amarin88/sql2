-- Crear la base de datos
CREATE DATABASE ConsultorioKinesiologia;
USE ConsultorioKinesiologia;

-- Tabla: Pacientes
CREATE TABLE Pacientes (
    idPaciente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    fechaNacimiento DATE NOT NULL,
    telefono VARCHAR(15),
    email VARCHAR(100),
    direccion VARCHAR(150)
);

-- Tabla: Profesionales
CREATE TABLE Profesionales (
    idProfesional INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    especialidad VARCHAR(100),
    matricula VARCHAR(50) UNIQUE NOT NULL
);

-- Tabla: Turnos
CREATE TABLE Turnos (
    idTurno INT AUTO_INCREMENT PRIMARY KEY,
    idPaciente INT NOT NULL,
    idProfesional INT NOT NULL,
    fechaHora DATETIME NOT NULL,
    motivo VARCHAR(200),
    estado ENUM('Pendiente', 'Realizado', 'Cancelado') DEFAULT 'Pendiente',
    FOREIGN KEY (idPaciente) REFERENCES Pacientes(idPaciente),
    FOREIGN KEY (idProfesional) REFERENCES Profesionales(idProfesional)
);

-- Tabla: Tratamientos
CREATE TABLE Tratamientos (
    idTratamiento INT AUTO_INCREMENT PRIMARY KEY,
    nombreTratamiento VARCHAR(100) NOT NULL,
    descripcion TEXT,
    duracionEstimada INT COMMENT 'Duración en minutos'
);

-- Tabla: Sesiones
CREATE TABLE Sesiones (
    idSesion INT AUTO_INCREMENT PRIMARY KEY,
    idTurno INT NOT NULL,
    idTratamiento INT NOT NULL,
    fechaHora DATETIME NOT NULL,
    notas TEXT,
    FOREIGN KEY (idTurno) REFERENCES Turnos(idTurno),
    FOREIGN KEY (idTratamiento) REFERENCES Tratamientos(idTratamiento)
);

-- Tabla: Diagnosticos
CREATE TABLE Diagnosticos (
    idDiagnostico INT AUTO_INCREMENT PRIMARY KEY,
    idPaciente INT NOT NULL,
    descripcion TEXT NOT NULL,
    fechaDiagnostico DATE NOT NULL,
    FOREIGN KEY (idPaciente) REFERENCES Pacientes(idPaciente)
);

-- Tabla: Facturas
CREATE TABLE Facturas (
    idFactura INT AUTO_INCREMENT PRIMARY KEY,
    idPaciente INT NOT NULL,
    fechaEmision DATE NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (idPaciente) REFERENCES Pacientes(idPaciente)
);

-- Tabla: DetalleFactura
CREATE TABLE DetalleFactura (
    idDetalle INT AUTO_INCREMENT PRIMARY KEY,
    idFactura INT NOT NULL,
    idTratamiento INT NOT NULL,
    cantidad INT NOT NULL,
    precioUnitario DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (idFactura) REFERENCES Facturas(idFactura),
    FOREIGN KEY (idTratamiento) REFERENCES Tratamientos(idTratamiento)
);

-- Tabla: HistorialClinico
CREATE TABLE HistorialClinico (
    idHistorial INT AUTO_INCREMENT PRIMARY KEY,
    idPaciente INT NOT NULL,
    descripcion TEXT NOT NULL,
    fechaRegistro DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (idPaciente) REFERENCES Pacientes(idPaciente)
);

-- Vistas
-- Vista: VistaTurnosPendientes
-- Descripción: Muestra una lista de todos los turnos pendientes junto con los datos del paciente y profesional asociado.
CREATE VIEW VistaTurnosPendientes AS
SELECT 
    t.idTurno,
    CONCAT(p.nombre, ' ', p.apellido) AS nombrePaciente,
    CONCAT(pr.nombre, ' ', pr.apellido) AS nombreProfesional,
    t.fechaHora,
    t.motivo
FROM 
    Turnos t
JOIN Pacientes p ON t.idPaciente = p.idPaciente
JOIN Profesionales pr ON t.idProfesional = pr.idProfesional
WHERE 
    t.estado = 'Pendiente';

-- Vista: VistaFacturasPacientes
-- Descripción: Proporciona un detalle de las facturas emitidas por paciente, incluyendo el total de cada factura.
CREATE VIEW VistaFacturasPacientes AS
SELECT 
    f.idFactura,
    CONCAT(p.nombre, ' ', p.apellido) AS nombrePaciente,
    f.fechaEmision,
    f.total
FROM 
    Facturas f
JOIN Pacientes p ON f.idPaciente = p.idPaciente;

-- Vista: VistaHistorialClinico
-- Descripción: Detalla el historial clínico de los pacientes con la fecha y descripción de cada entrada.
CREATE VIEW VistaHistorialClinico AS
SELECT 
    h.idHistorial,
    CONCAT(p.nombre, ' ', p.apellido) AS nombrePaciente,
    h.descripcion,
    h.fechaRegistro
FROM 
    HistorialClinico h
JOIN Pacientes p ON h.idPaciente = p.idPaciente;

-- Funciones
-- Función: CalcularEdad
-- Descripción: Calcula la edad de un paciente en base a su fecha de nacimiento.
DELIMITER //
CREATE FUNCTION CalcularEdad(fechaNacimiento DATE) RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE edad INT;
    SET edad = TIMESTAMPDIFF(YEAR, fechaNacimiento, CURDATE());
    RETURN edad;
END //
DELIMITER ;

-- Función: TotalFacturacionPorPaciente
-- Descripción: Devuelve el monto total facturado a un paciente específico.
DELIMITER //
CREATE FUNCTION TotalFacturacionPorPaciente(idPaciente INT) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(10,2);
    SELECT SUM(total) INTO total
    FROM Facturas
    WHERE idPaciente = idPaciente;
    RETURN total;
END //
DELIMITER ;

-- Stored Procedures
-- Stored Procedure: CrearTurno
-- Descripción: Permite registrar un nuevo turno asociando a un paciente y un profesional.
DELIMITER //
CREATE PROCEDURE CrearTurno(
    IN p_idPaciente INT,
    IN p_idProfesional INT,
    IN p_fechaHora DATETIME,
    IN p_motivo VARCHAR(200)
)
BEGIN
    INSERT INTO Turnos (idPaciente, idProfesional, fechaHora, motivo, estado)
    VALUES (p_idPaciente, p_idProfesional, p_fechaHora, p_motivo, 'Pendiente');
END //
DELIMITER ;

-- Stored Procedure: ActualizarEstadoTurno
-- Descripción: Actualiza el estado de un turno a "Realizado" o "Cancelado".
DELIMITER //
CREATE PROCEDURE ActualizarEstadoTurno(
    IN p_idTurno INT,
    IN p_estado ENUM('Pendiente', 'Realizado', 'Cancelado')
)
BEGIN
    UPDATE Turnos
    SET estado = p_estado
    WHERE idTurno = p_idTurno;
END //
DELIMITER ;

-- Insertar profesionales
INSERT INTO Profesionales (nombre, apellido, especialidad, matricula)
VALUES
('Carlos', 'Ruiz', 'Kinesiología', 'K-12345'),
('Laura', 'Sánchez', 'Fisioterapia', 'F-54321'),
('Ricardo', 'González', 'Rehabilitación', 'R-67890');

-- Insertar pacientes
INSERT INTO Pacientes (nombre, apellido, fechaNacimiento, telefono, email, direccion)
VALUES
('Pedro', 'López', '1995-01-22', '2612233445', 'pedro.lopez@email.com', 'Calle Libertad 321, Mendoza'),
('María', 'Rodríguez', '1988-08-14', '2613344556', 'maria.rodriguez@email.com', 'Avenida Mitre 987, Mendoza'),
('Javier', 'Sosa', '1993-10-05', '2614455667', 'javier.sosa@email.com', 'Calle Mendoza 567, Mendoza'),
('Paola', 'Hernández', '1997-02-20', '2615566778', 'paola.hernandez@email.com', 'Calle San Juan 890, Mendoza'),
('Carlos', 'Pérez', '1984-06-30', '2616677889', 'carlos.perez@email.com', 'Calle 9 de Julio 123, Mendoza'),
('Lucía', 'Díaz', '2000-04-15', '2617788990', 'lucia.diaz@email.com', 'Calle Belgrano 456, Mendoza'),
('Santiago', 'González', '1991-09-12', '2618899001', 'santiago.gonzalez@email.com', 'Calle Corrientes 654, Mendoza'),
('Eva', 'Martínez', '1986-07-27', '2619001122', 'eva.martinez@email.com', 'Avenida San Martín 321, Mendoza'),
('Martín', 'Fernández', '1992-11-03', '2610112233', 'martin.fernandez@email.com', 'Calle Rivadavia 789, Mendoza'),
('Fernanda', 'Mendoza', '1994-12-17', '2612233445', 'fernanda.mendoza@email.com', 'Avenida Peltier 456, Mendoza');

-- Insertar turnos
INSERT INTO Turnos (idPaciente, idProfesional, fechaHora, motivo, estado)
VALUES
(4, 2, '2024-12-21 10:00:00', 'Dolor cervical', 'Pendiente'),
(5, 3, '2024-12-22 11:00:00', 'Esguince de rodilla', 'Pendiente'),
(6, 1, '2024-12-23 12:00:00', 'Tendinitis en muñeca', 'Pendiente'),
(7, 2, '2024-12-24 13:30:00', 'Recuperación post cirugía', 'Pendiente'),
(8, 3, '2024-12-25 14:00:00', 'Lesión en hombro', 'Pendiente'),
(9, 1, '2024-12-26 15:00:00', 'Dolor de espalda baja', 'Pendiente'),
(10, 2, '2024-12-27 16:00:00', 'Fractura de tobillo', 'Pendiente'),
(1, 3, '2024-12-28 17:00:00', 'Dolor en rodillas', 'Pendiente'),
(2, 1, '2024-12-29 18:00:00', 'Contractura muscular', 'Pendiente'),
(3, 2, '2024-12-30 19:00:00', 'Lesión en codo', 'Pendiente');

-- Insertar tratamientos
INSERT INTO Tratamientos (nombreTratamiento, descripcion, duracionEstimada)
VALUES
('Masoterapia', 'Terapia basada en masajes terapéuticos para aliviar tensiones.', 40),
('Crioterapia', 'Aplicación de frío para reducir inflamación y dolor.', 20),
('Ultracavitación', 'Tratamiento no invasivo para la eliminación de grasa localizada.', 60),
('Reeducación postural', 'Conjunto de ejercicios y técnicas para mejorar la postura corporal.', 45),
('Taping neuromuscular', 'Uso de vendajes elásticos para aliviar el dolor y facilitar el movimiento.', 30),
('Laserterapia', 'Uso de luz láser para estimular la curación y aliviar el dolor.', 35),
('Masaje deportivo', 'Masajes terapéuticos para mejorar el rendimiento deportivo y reducir lesiones.', 50),
('Estiramientos asistidos', 'Ejercicios de estiramiento guiados para mejorar la flexibilidad y prevenir lesiones.', 30),
('Rehabilitación funcional', 'Programas de ejercicios para recuperar la funcionalidad de la extremidad afectada.', 55),
('Terapia de presión negativa', 'Uso de presión negativa para ayudar en la cicatrización de heridas.', 40);

-- Insertar sesiones
INSERT INTO Sesiones (idTurno, idTratamiento, fechaHora, notas)
VALUES
(4, 1, '2024-12-21 10:30:00', 'Sesión de masoterapia para dolor cervical y reducción de tensión.'),
(5, 3, '2024-12-22 11:30:00', 'Ultracavitación para tratar esguince de rodilla.'),
(6, 2, '2024-12-23 12:30:00', 'Crioterapia para reducir inflamación en muñeca.'),
(7, 4, '2024-12-24 14:00:00', 'Reeducación postural para mejorar postura post quirúrgica.'),
(8, 5, '2024-12-25 14:30:00', 'Taping neuromuscular en hombro para aliviar dolor.'),
(9, 6, '2024-12-26 15:30:00', 'Laserterapia para tratar dolor en espalda baja.'),
(10, 7, '2024-12-27 16:30:00', 'Masaje deportivo para recuperación de tobillo fracturado.'),
(1, 8, '2024-12-28 17:30:00', 'Estiramientos asistidos para dolor de rodillas.'),
(2, 9, '2024-12-29 18:30:00', 'Rehabilitación funcional para contractura muscular.'),
(3, 10, '2024-12-30 19:30:00', 'Terapia de presión negativa para codo lesionado.');

-- Insertar diagnósticos
INSERT INTO Diagnosticos (idPaciente, descripcion, fechaDiagnostico)
VALUES
(4, 'Contractura cervical crónica debido a malas posturas.', '2024-12-10'),
(5, 'Es posible esguince de grado II en rodilla izquierda.', '2024-12-12'),
(6, 'Tendinitis en muñeca por esfuerzo repetitivo.', '2024-12-14'),
(7, 'Recuperación postquirúrgica tras cirugía de cadera.', '2024-12-16'),
(8, 'Lesión en el manguito rotador del hombro derecho.', '2024-12-17'),
(9, 'Desgaste articular en rodillas por actividad física excesiva.', '2024-12-18'),
(10, 'Fractura de tobillo con desplazamiento de hueso.', '2024-12-19'),
(1, 'Dolor lumbar asociado a postura incorrecta en oficina.', '2024-12-20'),
(2, 'Contractura muscular en trapecio por estrés.', '2024-12-21'),
(3, 'Lesión en codo por sobreuso en entrenamiento de tenis.', '2024-12-22');

-- Insertar facturas
INSERT INTO Facturas (idPaciente, fechaEmision, total)
VALUES
(4, '2024-12-21', 1350.00),
(5, '2024-12-22', 1600.00),
(6, '2024-12-23', 1800.00),
(7, '2024-12-24', 1400.00),
(8, '2024-12-25', 1500.00),
(9, '2024-12-26', 1700.00),
(10, '2024-12-27', 1450.00),
(1, '2024-12-28', 1250.00),
(2, '2024-12-29', 1550.00),
(3, '2024-12-30', 2000.00);

-- Insertar detalles de factura
INSERT INTO DetalleFactura (idFactura, idTratamiento, cantidad, precioUnitario)
VALUES
(11, 1, 1, 450.00),
(11, 2, 1, 400.00),
(12, 3, 1, 500.00),
(12, 4, 1, 600.00),
(13, 5, 1, 700.00),
(13, 6, 1, 500.00),
(14, 7, 1, 800.00),
(14, 8, 1, 600.00),
(15, 9, 1, 750.00),
(15, 10, 1, 650.00);
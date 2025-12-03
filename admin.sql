SET search_path TO admin;

DROP TABLE IF EXISTS session CASCADE;
DROP TABLE IF EXISTS user_identity CASCADE;
DROP TABLE IF EXISTS submission CASCADE;
DROP TABLE IF EXISTS announcement CASCADE;
DROP TABLE IF EXISTS timeline CASCADE;
DROP TABLE IF EXISTS event_participant CASCADE;
DROP TABLE IF EXISTS team_member CASCADE;
DROP TABLE IF EXISTS team CASCADE;
DROP TABLE IF EXISTS media CASCADE;
DROP TABLE IF EXISTS event CASCADE;
DROP TABLE IF EXISTS "User" CASCADE;

-- pastikan user admin ada di tabel User
INSERT INTO "User" (email, full_name)
VALUES ('najma060726@gmail.com', 'Admin User')
RETURNING user_id;

INSERT INTO user_identity (
    email, identity_provider, hash, verifying_status, user_id
) VALUES (
    'najma060726@gmail.com',
    'local',
    md5('admin1234'),
    'Verified',
    1 
);

CREATE TABLE Media (
    Media_ID INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Media_Grouping VARCHAR(100),
    Type VARCHAR(50),
    Created_At TIMESTAMP,
    Updated_At TIMESTAMP,
    Uploader VARCHAR(255),
    Event_ID INT,
    User_ID INT
);



CREATE TABLE "User" (
    User_ID INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Email VARCHAR(255) NOT NULL UNIQUE,
    Full_Name VARCHAR(255) NOT NULL,
    Birth_Date DATE,
    Pendidikan VARCHAR(100),
    Nama_Sekolah VARCHAR(255),
    Entry_Source VARCHAR(50),
    Phone_Number VARCHAR(20),
    ID_Line VARCHAR(50),
    ID_Discord VARCHAR(50),
    ID_Instagram VARCHAR(50),
    KTM_Key VARCHAR(255),
    Twibbon_Key VARCHAR(255),
    Jenis_Kelamin CHAR(1),
    Registration_Status VARCHAR(50),
    Created_At TIMESTAMP,
    Updated_At TIMESTAMP,
    Media_ID INT,
    CONSTRAINT FK_User_Media FOREIGN KEY (Media_ID) REFERENCES Media(Media_ID)
);

ALTER TABLE admin."User"
ADD COLUMN user_code VARCHAR(10);
UPDATE admin."User"
SET user_code = 'U' || LPAD(user_id::text, 3, '0');

CREATE OR REPLACE FUNCTION auto_user_code()
RETURNS trigger AS $$
BEGIN
    NEW.user_code := 'U' || LPAD(NEW.user_id::text, 3, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_user_code ON admin."User";

CREATE TRIGGER trg_user_code
AFTER INSERT ON admin."User"
FOR EACH ROW
EXECUTE FUNCTION auto_user_code();


CREATE TABLE Event (
    Event_ID INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Title VARCHAR(255) NOT NULL,
    Description TEXT,
    Guidebook_URL VARCHAR(255),
    Contact_Person_1 VARCHAR(255),
    Contact_Person_2 VARCHAR(255),
    Max_Noncompetition_Participant INT,
    Event_Type VARCHAR(50),
    Media_ID INT,
    CONSTRAINT FK_Event_Media FOREIGN KEY (Media_ID) REFERENCES Media(Media_ID)
);
ALTER TABLE admin.event
ADD COLUMN IF NOT EXISTS event_code VARCHAR(10);

UPDATE admin.event
SET event_code = 'E' || LPAD(event_id::text, 3, '0');


ALTER TABLE Media
ADD CONSTRAINT FK_Media_Event FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID),
ADD CONSTRAINT FK_Media_User FOREIGN KEY (User_ID) REFERENCES "User"(User_ID);

CREATE TABLE Team_Member (
    Team_Member_ID INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Member_Role VARCHAR(50),
    Kartu_ID VARCHAR(255),
    Verification_Error VARCHAR(255),
    User_ID INT NOT NULL UNIQUE,
    Team_ID INT,
    CONSTRAINT FK_TM_User FOREIGN KEY (User_ID) REFERENCES "User"(User_ID)
);

CREATE TABLE Team (
    Team_ID INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Team_Name VARCHAR(255) NOT NULL UNIQUE,
    Team_Code VARCHAR(50),
    Max_Member INT CHECK (Max_Member > 0),
    Payment_Proof VARCHAR(255),
    Verifying_Status VARCHAR(50),
    Verifying_Error VARCHAR(255),
    Created_At TIMESTAMP,
    Updated_At TIMESTAMP,
    Event_ID INT NOT NULL,
    Team_Member_ID INT,
    CONSTRAINT FK_Team_Event FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID),
    CONSTRAINT FK_Team_TeamMember FOREIGN KEY (Team_Member_ID) REFERENCES Team_Member(Team_Member_ID)
);

UPDATE admin.team
SET team_code = 'T' || LPAD(team_id::text, 3, '0');

ALTER TABLE Team_Member
ADD CONSTRAINT FK_TM_Team FOREIGN KEY (Team_ID) REFERENCES Team(Team_ID);

CREATE TABLE Timeline (
    Event_Timeline_ID INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Timeline_Title VARCHAR(255),
    Date DATE,
    Event VARCHAR(255),
    Event_ID INT NOT NULL,
    CONSTRAINT FK_Timeline_Event FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID)
);

CREATE TABLE Announcement (
    Event_Announcement_ID INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Title VARCHAR(255) NOT NULL,
    Description TEXT NOT NULL,
    Author VARCHAR(255),
    Created_At TIMESTAMP,
    Updated_At TIMESTAMP,
    Competition VARCHAR(50),
    Event_ID INT NOT NULL,
    User_ID INT,
    CONSTRAINT FK_Ann_Event FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID),
    CONSTRAINT FK_Ann_User FOREIGN KEY (User_ID) REFERENCES "User"(User_ID)
);

CREATE TABLE Submission (
    Competition_Submission_ID INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Submission_Object VARCHAR(255) NOT NULL,
    Created_At TIMESTAMP NOT NULL,
    Updated_At TIMESTAMP,
    Team_ID INT NOT NULL,
    Event_ID INT NOT NULL,
    CONSTRAINT FK_Sub_Team FOREIGN KEY (Team_ID) REFERENCES Team(Team_ID),
    CONSTRAINT FK_Sub_Event FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID)
);

CREATE TABLE Event_Participant (
    Participant_ID INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Date_Added DATE,
    Payment_Proof VARCHAR(255),
    Payment_Verification VARCHAR(50),
    Bundling VARCHAR(50),
    Paid_For_User INT,
    User_ID INT NOT NULL UNIQUE,
    Event_ID INT NOT NULL,
    CONSTRAINT FK_EP_User FOREIGN KEY (User_ID) REFERENCES "User"(User_ID),
    CONSTRAINT FK_EP_Event FOREIGN KEY (Event_ID) REFERENCES Event(Event_ID)
);

CREATE TABLE User_Identity (
    Identity_ID INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Email VARCHAR(255),
    Identity_Provider VARCHAR(50),
    Hash VARCHAR(255) NOT NULL,
    Verifying_Status VARCHAR(50),
    Verifying_Token VARCHAR(255),
    Verifying_Token_Expiration TIMESTAMP,
    Password_Recovery_Token VARCHAR(255),
    Password_Recovery_Token_Expiration TIMESTAMP,
    Created_At TIMESTAMP,
    Updated_At TIMESTAMP,
    User_ID INT NOT NULL UNIQUE,
    CONSTRAINT FK_UIdentity_User FOREIGN KEY (User_ID) REFERENCES "User"(User_ID)
);

CREATE TABLE Session (
    Session_ID INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Expires TIMESTAMP,
    Data TEXT,
    User_ID INT NOT NULL,
    CONSTRAINT FK_Session_User FOREIGN KEY (User_ID) REFERENCES "User"(User_ID)
);


INSERT INTO Event (
    Title, Description, Guidebook_URL,
    Contact_Person_1, Contact_Person_2,
    Max_Noncompetition_Participant, Event_Type, Media_ID
)
VALUES
('CPToday',   'Lomba pemrograman kompetitif tingkat nasional untuk pelajar dan mahasiswa.', 'guidebook_cp.pdf',   '081234567801', '081234567802', 50, 'Competition', NULL),
('UXToday',   'Lomba perancangan antarmuka dan pengalaman pengguna berbasis mobile/web.',   'guidebook_ux.pdf',   '081234567803', '081234567804', 50, 'Competition', NULL),
('HackToday', 'Capture The Flag dengan berbagai kategori keamanan siber.',                  'guidebook_ctf.pdf',  '081234567805', '081234567806', 50, 'Competition', NULL),
('MineToday', 'Kompetisi analisis data dan machine learning untuk memecahkan masalah nyata.','guidebook_mine.pdf', '081234567807', '081234567808', 50, 'Competition', NULL),
('GameToday', 'Kompetisi pembuatan game 2D/3D menggunakan engine pilihan peserta.',         'guidebook_gamedev.pdf','081234567809','081234567810',50, 'Competition', NULL);

SELECT MIN(User_ID), MAX(User_ID), COUNT(*)
FROM "User";


INSERT INTO "User" (
    Email, Full_Name, Birth_Date, Pendidikan, Nama_Sekolah, Entry_Source,
    Phone_Number, ID_Line, ID_Discord, ID_Instagram, KTM_Key, Twibbon_Key,
    Jenis_Kelamin, Registration_Status, Created_At, Updated_At, Media_ID
) VALUES
('aira.nakamori@gmail.com', 'Aira Nakamori', '2004-06-11', 'Mahasiswa', 'Universitas Indonesia', 'Instagram', '081297654321', 'aira123', 'aira#1021', 'aira_221', 'ktm_aira.pdf', 'twibbon_aira.png', 'P', 'Approved', NOW(), NOW(), NULL),
('davin.ichikawa@gmail.com', 'Davin Ichikawa', '2003-08-23', 'Mahasiswa', 'Telkom University', 'Teman', '081289765432', 'davin122', 'davin#9843', 'davin_10', 'ktm_davin.pdf', 'twibbon_davin.png', 'L', 'Approved', NOW(), NOW(), NULL),
('zahra.miyamoto@gmail.com', 'Zahra Miyamoto', '2005-03-19', 'Mahasiswa', 'Universitas Brawijaya', 'Instagram', '081231445678', 'zahra22', 'zahra#7474', 'zahra_661', 'ktm_zahra.pdf', 'twibbon_zahra.png', 'P', 'Approved', NOW(), NOW(), NULL),
('rafa.kunimoto@gmail.com', 'Rafa Kunimoto', '2002-12-02', 'Mahasiswa', 'Universitas Airlangga', 'Website', '081257839201', 'rafa910', 'rafa#2381', 'rafa_012', 'ktm_rafa.pdf', 'twibbon_rafa.png', 'L', 'Approved', NOW(), NOW(), NULL),
('salsa.hanazawa@gmail.com', 'Salsa Hanazawa', '2004-01-21', 'Mahasiswa', 'Universitas Gadjah Mada', 'Instagram', '081298701234', 'salsa777', 'salsa#1524', 'salsa_199', 'ktm_salsa.pdf', 'twibbon_salsa.png', 'P', 'Approved', NOW(), NOW(), NULL),
('naya.takashiro@gmail.com', 'Naya Takashiro', '2003-11-05', 'Mahasiswa', 'Politeknik Elektronika Negeri Surabaya', 'Teman', '081298456702', 'naya441', 'naya#2883', 'naya_502', 'ktm_naya.pdf', 'twibbon_naya.png', 'P', 'Approved', NOW(), NOW(), NULL),
('fadil.yamashita@gmail.com', 'Fadil Yamashita', '2004-09-14', 'Mahasiswa', 'Institut Teknologi Sepuluh Nopember', 'Instagram', '081289321567', 'fadil92', 'fadil#7711', 'fadil_113', 'ktm_fadil.pdf', 'twibbon_fadil.png', 'L', 'Approved', NOW(), NOW(), NULL),
('keira.ando@gmail.com', 'Keira Ando', '2005-07-29', 'Mahasiswa', 'Universitas Padjadjaran', 'Website', '081291342667', 'keira77', 'keira#3201', 'keira_221', 'ktm_keira.pdf', 'twibbon_keira.png', 'P', 'Approved', NOW(), NOW(), NULL),
('yuta.shinoda@gmail.com', 'Yuta Shinoda', '2002-05-09', 'Mahasiswa', 'Universitas Diponegoro', 'Instagram', '081289943211', 'yuta33', 'yuta#6235', 'yuta_663', 'ktm_yuta.pdf', 'twibbon_yuta.png', 'L', 'Approved', NOW(), NOW(), NULL),
('hanin.kisaragi@gmail.com', 'Hanin Kisaragi', '2003-02-12', 'Mahasiswa', 'Universitas Sebelas Maret', 'Teman', '081254987321', 'hanin88', 'hanin#7221', 'hanin_622', 'ktm_hanin.pdf', 'twibbon_hanin.png', 'P', 'Approved', NOW(), NOW(), NULL),
('rin.ayagawa@gmail.com', 'Rin Ayagawa', '2004-10-18', 'Mahasiswa', 'Universitas Hasanuddin', 'Instagram', '081243567890', 'rin908', 'rin#1343', 'rin_093', 'ktm_rin.pdf', 'twibbon_rin.png', 'P', 'Approved', NOW(), NOW(), NULL),
('ray.kisaragi@gmail.com', 'Ray Kisaragi', '2003-06-07', 'Mahasiswa', 'Politeknik Negeri Jakarta', 'Instagram', '081235292210', 'ray192', 'ray#9033', 'ray_312', 'ktm_ray.pdf', 'twibbon_ray.png', 'L', 'Approved', NOW(), NOW(), NULL),
('sena.morita@gmail.com', 'Sena Morita', '2005-04-11', 'Mahasiswa', 'Universitas Negeri Surabaya', 'Website', '081244119922', 'sena882', 'sena#1188', 'sena_700', 'ktm_sena.pdf', 'twibbon_sena.png', 'L', 'Approved', NOW(), NOW(), NULL),
('alya.satomi@gmail.com', 'Alya Satomi', '2004-02-16', 'Mahasiswa', 'Universitas Andalas', 'Instagram', '081277665432', 'alya561', 'alya#2541', 'alya_871', 'ktm_alya.pdf', 'twibbon_alya.png', 'P', 'Approved', NOW(), NOW(), NULL),
('mahesa.akiyama@gmail.com', 'Mahesa Akiyama', '2002-10-02', 'Mahasiswa', 'Universitas Sriwijaya', 'Instagram', '081219144888', 'mahesa202', 'mahesa#9001', 'mahesa_001', 'ktm_mahesa.pdf', 'twibbon_mahesa.png', 'L', 'Approved', NOW(), NOW(), NULL);

INSERT INTO "User" (
    Email, Full_Name, Birth_Date, Pendidikan, Nama_Sekolah, Entry_Source,
    Phone_Number, ID_Line, ID_Discord, ID_Instagram, KTM_Key, Twibbon_Key,
    Jenis_Kelamin, Registration_Status, Created_At, Updated_At, Media_ID
) VALUES
('sakura.minato@gmail.com', 'Sakura Minato', '2004-08-22', 'Mahasiswa', 'Universitas Indonesia', 'Instagram', '081289771221', 'sakura119', 'sakura#7783', 'sakura_190', 'ktm_sakura.pdf', 'twibbon_sakura.png', 'P', 'Approved', NOW(), NOW(), NULL),
('naoki.pranoto@gmail.com', 'Naoki Pranoto', '2003-10-15', 'Mahasiswa', 'Politeknik Negeri Jakarta', 'Teman', '081245679812', 'naoki811', 'naoki#9881', 'naoki_321', 'ktm_naoki.pdf', 'twibbon_naoki.png', 'L', 'Approved', NOW(), NOW(), NULL),
('layla.hisamoto@gmail.com', 'Layla Hisamoto', '2004-01-04', 'Mahasiswa', 'Universitas Airlangga', 'Website', '081231987665', 'layla811', 'layla#3311', 'layla_810', 'ktm_layla.pdf', 'twibbon_layla.png', 'P', 'Approved', NOW(), NOW(), NULL),
('rio.kitagawa@gmail.com', 'Rio Kitagawa', '2005-05-21', 'Mahasiswa', 'Universitas Gadjah Mada', 'Instagram', '081299124675', 'rio773', 'rio#1902', 'rio_122', 'ktm_rio.pdf', 'twibbon_rio.png', 'L', 'Approved', NOW(), NOW(), NULL),
('hana.kuroishi@gmail.com', 'Hana Kuroishi', '2002-12-27', 'Mahasiswa', 'Telkom University', 'Teman', '081298312561', 'hana440', 'hana#2981', 'hana_822', 'ktm_hana.pdf', 'twibbon_hana.png', 'P', 'Approved', NOW(), NOW(), NULL),
('daigo.ramadhan@gmail.com', 'Daigo Ramadhan', '2003-07-01', 'Mahasiswa', 'Universitas Diponegoro', 'Instagram', '081222391015', 'daigo100', 'daigo#8544', 'daigo_811', 'ktm_daigo.pdf', 'twibbon_daigo.png', 'L', 'Approved', NOW(), NOW(), NULL),
('ayumi.setiawan@gmail.com', 'Ayumi Setiawan', '2004-04-10', 'Mahasiswa', 'Universitas Brawijaya', 'Website', '081233876521', 'ayumi721', 'ayumi#9921', 'ayumi_010', 'ktm_ayumi.pdf', 'twibbon_ayumi.png', 'P', 'Approved', NOW(), NOW(), NULL),
('kenji.putrawan@gmail.com', 'Kenji Putrawan', '2005-09-12', 'Mahasiswa', 'Universitas Hasanuddin', 'Teman', '081278432100', 'kenji782', 'kenji#1147', 'kenji_762', 'ktm_kenji.pdf', 'twibbon_kenji.png', 'L', 'Approved', NOW(), NOW(), NULL),
('maya.higurashi@gmail.com', 'Maya Higurashi', '2003-03-06', 'Mahasiswa', 'Universitas Udayana', 'Instagram', '081267452111', 'maya821', 'maya#5512', 'maya_801', 'ktm_maya.pdf', 'twibbon_maya.png', 'P', 'Approved', NOW(), NOW(), NULL),
('ryu.andikaputra@gmail.com', 'Ryu Andikaputra', '2002-09-08', 'Mahasiswa', 'Institut Teknologi Sepuluh Nopember', 'Instagram', '081296321221', 'ryu554', 'ryu#0081', 'ryu_772', 'ktm_ryu.pdf', 'twibbon_ryu.png', 'L', 'Approved', NOW(), NOW(), NULL),
('nana.wijayanti@gmail.com', 'Nana Wijayanti', '2004-10-09', 'Mahasiswa', 'Universitas Negeri Surabaya', 'Teman', '081255136290', 'nana341', 'nana#7712', 'nana_712', 'ktm_nana.pdf', 'twibbon_nana.png', 'P', 'Approved', NOW(), NOW(), NULL),
('haru.berliano@gmail.com', 'Haru Berliano', '2005-06-23', 'Mahasiswa', 'Universitas Padjadjaran', 'Website', '081265432211', 'haru167', 'haru#8211', 'haru_190', 'ktm_haru.pdf', 'twibbon_haru.png', 'L', 'Approved', NOW(), NOW(), NULL),
('hanae.kristiani@gmail.com', 'Hanae Kristiani', '2004-03-11', 'Mahasiswa', 'IPB University', 'Instagram', '081291773201', 'hanae20', 'hanae#9733', 'hanae_513', 'ktm_hanae.pdf', 'twibbon_hanae.png', 'P', 'Approved', NOW(), NOW(), NULL),
('kaoru.fitriansyah@gmail.com', 'Kaoru Fitriansyah', '2003-12-01', 'Mahasiswa', 'BINUS University', 'Website', '081255764001', 'kaoru22', 'kaoru#4091', 'kaoru_419', 'ktm_kaoru.pdf', 'twibbon_kaoru.png', 'L', 'Approved', NOW(), NOW(), NULL),
('sayuri.pamungkas@gmail.com', 'Sayuri Pamungkas', '2005-11-07', 'Mahasiswa', 'Universitas Negeri Jakarta', 'Instagram', '081214987632', 'sayuri64', 'sayuri#2115', 'sayuri_110', 'ktm_sayuri.pdf', 'twibbon_sayuri.png', 'P', 'Approved', NOW(), NOW(), NULL),
('ryota.nugraha@gmail.com', 'Ryota Nugraha', '2003-10-26', 'Mahasiswa', 'Universitas Dian Nuswantoro', 'Teman', '081276593430', 'ryota712', 'ryota#4102', 'ryota_311', 'ktm_ryota.pdf', 'twibbon_ryota.png', 'L', 'Approved', NOW(), NOW(), NULL),
('momoka.putri@gmail.com', 'Momoka Putri', '2004-05-19', 'Mahasiswa', 'Universitas Gunadarma', 'Instagram', '081256598761', 'momoka44', 'momoka#7812', 'momoka_515', 'ktm_momoka.pdf', 'twibbon_momoka.png', 'P', 'Approved', NOW(), NOW(), NULL),
('yugo.firmansyah@gmail.com', 'Yugo Firmansyah', '2002-11-11', 'Mahasiswa', 'Universitas Telkom', 'Instagram', '081278565290', 'yugo933', 'yugo#4119', 'yugo_777', 'ktm_yugo.pdf', 'twibbon_yugo.png', 'L', 'Approved', NOW(), NOW(), NULL),
('hinata.susanto@gmail.com', 'Hinata Susanto', '2005-06-18', 'Mahasiswa', 'Universitas Katolik Parahyangan', 'Teman', '081234569012', 'hinata712', 'hinata#1893', 'hinata_884', 'ktm_hinata.pdf', 'twibbon_hinata.png', 'P', 'Approved', NOW(), NOW(), NULL),
('akito.wijaya@gmail.com', 'Akito Wijaya', '2003-07-28', 'Mahasiswa', 'Universitas Sam Ratulangi', 'Website', '081299461001', 'akito18', 'akito#2994', 'akito_114', 'ktm_akito.pdf', 'twibbon_akito.png', 'L', 'Approved', NOW(), NOW(), NULL),
('miura.hanifa@gmail.com', 'Miura Hanifa', '2004-04-11', 'Mahasiswa', 'Universitas Andalas', 'Instagram', '081243762111', 'miura819', 'miura#9291', 'miura_412', 'ktm_miura.pdf', 'twibbon_miura.png', 'P', 'Approved', NOW(), NOW(), NULL),
('ren.kusumah@gmail.com', 'Ren Kusumah', '2003-08-14', 'Mahasiswa', 'ITS Surabaya', 'Teman', '081218765590', 'ren991', 'ren#6620', 'ren_712', 'ktm_ren.pdf', 'twibbon_ren.png', 'L', 'Approved', NOW(), NOW(), NULL),
('hina.karimata@gmail.com', 'Hina Karimata', '2002-12-22', 'Mahasiswa', 'Universitas Mulawarman', 'Instagram', '081292117561', 'hina652', 'hina#1885', 'hina_211', 'ktm_hina.pdf', 'twibbon_hina.png', 'P', 'Approved', NOW(), NOW(), NULL),
('arata.surya@gmail.com', 'Arata Surya', '2005-01-08', 'Mahasiswa', 'Universitas Muhammadiyah Malang', 'Website', '081247863200', 'arata77', 'arata#5112', 'arata_504', 'ktm_arata.pdf', 'twibbon_arata.png', 'L', 'Approved', NOW(), NOW(), NULL),
('rinata.kinoshita@gmail.com', 'Rinata Kinoshita', '2003-03-21', 'Mahasiswa', 'Universitas Pancasila', 'Instagram', '081235674120', 'rinata02', 'rinata#6291', 'rinata_111', 'ktm_rinata.pdf', 'twibbon_rinata.png', 'P', 'Approved', NOW(), NOW(), NULL),
('mika.shimizu@gmail.com', 'Mika Shimizu', '2004-10-20', 'Mahasiswa', 'Universitas Mercu Buana', 'Teman', '081255513420', 'mika62', 'mika#9001', 'mika_012', 'ktm_mika.pdf', 'twibbon_mika.png', 'P', 'Approved', NOW(), NOW(), NULL),
('hideo.anggara@gmail.com', 'Hideo Anggara', '2002-02-28', 'Mahasiswa', 'Universitas Trisakti', 'Instagram', '081259319012', 'hideo341', 'hideo#18', 'hideo_551', 'ktm_hideo.pdf', 'twibbon_hideo.png', 'L', 'Approved', NOW(), NOW(), NULL),
('aisha.shindo@gmail.com', 'Aisha Shindo', '2005-09-10', 'Mahasiswa', 'Institut Pertanian Bogor', 'Instagram', '081234291555', 'aisha122', 'aisha#4771', 'aisha_390', 'ktm_aisha.pdf', 'twibbon_aisha.png', 'P', 'Approved', NOW(), NOW(), NULL),
('akira.winata@gmail.com', 'Akira Winata', '2003-11-26', 'Mahasiswa', 'Universitas Negeri Jakarta', 'Website', '081290527611', 'akira551', 'akira#7321', 'akira_231', 'ktm_akira.pdf', 'twibbon_akira.png', 'L', 'Approved', NOW(), NOW(), NULL),
('rena.fujiyanti@gmail.com', 'Rena Fujiyanti', '2004-08-16', 'Mahasiswa', 'Universitas Esa Unggul', 'Teman', '081277531988', 'rena711', 'rena#2034', 'rena_728', 'ktm_rena.pdf', 'twibbon_rena.png', 'P', 'Approved', NOW(), NOW(), NULL),
('izumi.naufal@gmail.com', 'Izumi Naufal', '2002-06-19', 'Mahasiswa', 'Universitas Jember', 'Instagram', '081291992010', 'izumi11', 'izumi#5931', 'izumi_551', 'ktm_izumi.pdf', 'twibbon_izumi.png', 'L', 'Approved', NOW(), NOW(), NULL),
('mei.ramadhanti@gmail.com', 'Mei Ramadhanti', '2005-04-17', 'Mahasiswa', 'Universitas Negeri Malang', 'Website', '081287652890', 'mei501', 'mei#1913', 'mei_811', 'ktm_mei.pdf', 'twibbon_mei.png', 'P', 'Approved', NOW(), NOW(), NULL);

INSERT INTO "User" (
    Email, Full_Name, Birth_Date, Pendidikan, Nama_Sekolah, Entry_Source,
    Phone_Number, ID_Line, ID_Discord, ID_Instagram, KTM_Key, Twibbon_Key,
    Jenis_Kelamin, Registration_Status, Created_At, Updated_At, Media_ID
) VALUES
('kenzo.maulana@gmail.com', 'Kenzo Maulana', '2004-07-17', 'Mahasiswa', 'Universitas Indonesia', 'Instagram', '081298100231', 'kenzo44', 'kenzo#8210', 'kenzo_991', 'ktm_kenzo.pdf', 'twibbon_kenzo.png', 'L', 'Approved', NOW(), NOW(), NULL),
('yuri.amalia@gmail.com', 'Yuri Amalia', '2003-03-25', 'Mahasiswa', 'Universitas Airlangga', 'Teman', '081255732100', 'yuri40', 'yuri#7150', 'yuri_502', 'ktm_yuri.pdf', 'twibbon_yuri.png', 'P', 'Approved', NOW(), NOW(), NULL),
('shiro.nugroho@gmail.com', 'Shiro Nugroho', '2002-11-29', 'Mahasiswa', 'Universitas Gadjah Mada', 'Website', '081234551221', 'shiro11', 'shiro#1882', 'shiro_766', 'ktm_shiro.pdf', 'twibbon_shiro.png', 'L', 'Approved', NOW(), NOW(), NULL),
('rena.pratiwi@gmail.com', 'Rena Pratiwi', '2005-01-03', 'Mahasiswa', 'Universitas Brawijaya', 'Instagram', '081254411298', 'rena24', 'rena#9912', 'rena_571', 'ktm_rena_p.pdf', 'twibbon_rena_p.png', 'P', 'Approved', NOW(), NOW(), NULL),
('itsuki.rahman@gmail.com', 'Itsuki Rahman', '2003-05-09', 'Mahasiswa', 'Institut Teknologi Bandung', 'Instagram', '081243613441', 'itsuki51', 'itsuki#1192', 'itsuki_901', 'ktm_itsuki.pdf', 'twibbon_itsuki.png', 'L', 'Approved', NOW(), NOW(), NULL),
('minami.putri@gmail.com', 'Minami Putri', '2004-08-15', 'Mahasiswa', 'Universitas Padjadjaran', 'Teman', '081231297665', 'minami10', 'minami#4121', 'minami_115', 'ktm_minami.pdf', 'twibbon_minami.png', 'P', 'Approved', NOW(), NOW(), NULL),
('daiki.alfarizi@gmail.com', 'Daiki Alfarizi', '2002-02-27', 'Mahasiswa', 'Universitas Negeri Surabaya', 'Website', '081249115520', 'daiki71', 'daiki#9622', 'daiki_558', 'ktm_daiki.pdf', 'twibbon_daiki.png', 'L', 'Approved', NOW(), NOW(), NULL),
('keiko.hartati@gmail.com', 'Keiko Hartati', '2004-10-08', 'Mahasiswa', 'Universitas Telkom', 'Instagram', '081273521201', 'keiko88', 'keiko#3312', 'keiko_311', 'ktm_keiko.pdf', 'twibbon_keiko.png', 'P', 'Approved', NOW(), NOW(), NULL),
('akira.firmanda@gmail.com', 'Akira Firmanda', '2003-06-22', 'Mahasiswa', 'IPB University', 'Instagram', '081276511299', 'akira441', 'akira#0121', 'akira_ff1', 'ktm_akira_f.pdf', 'twibbon_akira_f.png', 'L', 'Approved', NOW(), NOW(), NULL),
('hanae.setyawati@gmail.com', 'Hanae Setyawati', '2002-04-19', 'Mahasiswa', 'BINUS University', 'Teman', '081255687421', 'hanae100', 'hanae#5533', 'hanae_020', 'ktm_hanae_s.pdf', 'twibbon_hanae_s.png', 'P', 'Approved', NOW(), NOW(), NULL),
('shun.prayoga@gmail.com', 'Shun Prayoga', '2005-03-19', 'Mahasiswa', 'Universitas Diponegoro', 'Instagram', '081277634199', 'shun199', 'shun#8212', 'shun_200', 'ktm_shun.pdf', 'twibbon_shun.png', 'L', 'Approved', NOW(), NOW(), NULL),
('miyu.rahmadhani@gmail.com', 'Miyu Rahmadhani', '2003-12-30', 'Mahasiswa', 'Universitas Pasundan', 'Website', '081244333211', 'miyu88', 'miyu#5510', 'miyu_811', 'ktm_miyu.pdf', 'twibbon_miyu.png', 'P', 'Approved', NOW(), NOW(), NULL),
('rei.hakim@gmail.com', 'Rei Hakim', '2002-09-11', 'Mahasiswa', 'Universitas Trisakti', 'Instagram', '081278912621', 'rei22', 'rei#7199', 'rei_519', 'ktm_rei.pdf', 'twibbon_rei.png', 'L', 'Approved', NOW(), NOW(), NULL),
('erina.hanafiah@gmail.com', 'Erina Hanafiah', '2005-04-27', 'Mahasiswa', 'Universitas Negeri Jakarta', 'Instagram', '081243642011', 'erina42', 'erina#1292', 'erina_013', 'ktm_erina.pdf', 'twibbon_erina.png', 'P', 'Approved', NOW(), NOW(), NULL),
('kazuma.wijayanto@gmail.com', 'Kazuma Wijayanto', '2004-07-14', 'Mahasiswa', 'ITS Surabaya', 'Teman', '081298501221', 'kazuma12', 'kazuma#9931', 'kazuma_991', 'ktm_kazuma.pdf', 'twibbon_kazuma.png', 'L', 'Approved', NOW(), NOW(), NULL),
('yume.putriani@gmail.com', 'Yume Putriani', '2003-02-28', 'Mahasiswa', 'Universitas Pancasila', 'Website', '081255113209', 'yume55', 'yume#2210', 'yume_672', 'ktm_yume.pdf', 'twibbon_yume.png', 'P', 'Approved', NOW(), NOW(), NULL),
('touma.rizaldi@gmail.com', 'Touma Rizaldi', '2002-11-07', 'Mahasiswa', 'Universitas Sam Ratulangi', 'Instagram', '081287766281', 'touma92', 'touma#2901', 'touma_900', 'ktm_touma.pdf', 'twibbon_touma.png', 'L', 'Approved', NOW(), NOW(), NULL),
('emiri.nulanda@gmail.com', 'Emiri Nulanda', '2005-08-26', 'Mahasiswa', 'Universitas Gunadarma', 'Instagram', '081277721988', 'emiri41', 'emiri#8821', 'emiri_319', 'ktm_emiri.pdf', 'twibbon_emiri.png', 'P', 'Approved', NOW(), NOW(), NULL),
('hayato.syahputra@gmail.com', 'Hayato Syahputra', '2003-07-31', 'Mahasiswa', 'Universitas Udayana', 'Teman', '081289234611', 'hayato71', 'hayato#7101', 'hayato_711', 'ktm_hayato.pdf', 'twibbon_hayato.png', 'L', 'Approved', NOW(), NOW(), NULL),
('miaka.keban@gmail.com', 'Miaka Keban', '2004-03-22', 'Mahasiswa', 'Universitas Andalas', 'Website', '081243942100', 'miaka92', 'miaka#4901', 'miaka_718', 'ktm_miaka.pdf', 'twibbon_miaka.png', 'P', 'Approved', NOW(), NOW(), NULL),
('renzo.hidayat@gmail.com', 'Renzo Hidayat', '2002-08-10', 'Mahasiswa', 'Universitas Bina Nusantara', 'Instagram', '081245992210', 'renzo28', 'renzo#3950', 'renzo_991', 'ktm_renzo.pdf', 'twibbon_renzo.png', 'L', 'Approved', NOW(), NOW(), NULL),
('miku.arifin@gmail.com', 'Miku Arifin', '2005-02-11', 'Mahasiswa', 'Universitas Muhammadiyah Malang', 'Teman', '081271236900', 'miku18', 'miku#9714', 'miku_441', 'ktm_miku.pdf', 'twibbon_miku.png', 'P', 'Approved', NOW(), NOW(), NULL),
('leo.natsir@gmail.com', 'Leo Natsir', '2003-10-09', 'Mahasiswa', 'Universitas Hasanuddin', 'Instagram', '081244633120', 'leo81', 'leo#7117', 'leo_199', 'ktm_leo.pdf', 'twibbon_leo.png', 'L', 'Approved', NOW(), NOW(), NULL),
('minori.kartika@gmail.com', 'Minori Kartika', '2004-12-30', 'Mahasiswa', 'Universitas Negeri Yogyakarta', 'Website', '081254673122', 'minori72', 'minori#1001', 'minori_981', 'ktm_minori.pdf', 'twibbon_minori.png', 'P', 'Approved', NOW(), NOW(), NULL),
('ryo.darmawan@gmail.com', 'Ryo Darmawan', '2003-01-09', 'Mahasiswa', 'Universitas Sriwijaya', 'Instagram', '081267733201', 'ryo21', 'ryo#4911', 'ryo_902', 'ktm_ryo.pdf', 'twibbon_ryo.png', 'L', 'Approved', NOW(), NOW(), NULL),
('mei.puspita@gmail.com', 'Mei Puspita', '2002-05-22', 'Mahasiswa', 'Universitas Negeri Jakarta', 'Teman', '081233976521', 'mei19', 'mei#5511', 'mei_188', 'ktm_mei2.pdf', 'twibbon_mei2.png', 'P', 'Approved', NOW(), NOW(), NULL),
('taiga.rahmat@gmail.com', 'Taiga Rahmat', '2004-03-07', 'Mahasiswa', 'ITS Surabaya', 'Instagram', '081282211993', 'taiga87', 'taiga#7400', 'taiga_431', 'ktm_taiga.pdf', 'twibbon_taiga.png', 'L', 'Approved', NOW(), NOW(), NULL),
('selena.hanamichi@gmail.com', 'Selena Hanamichi', '2005-10-12', 'Mahasiswa', 'Universitas Negeri Surabaya', 'Instagram', '081266882900', 'selena12', 'selena#1782', 'selena_581', 'ktm_selena.pdf', 'twibbon_selena.png', 'P', 'Approved', NOW(), NOW(), NULL),
('hiro.susanto@gmail.com', 'Hiro Susanto', '2003-07-19', 'Mahasiswa', 'Universitas Telkom', 'Teman', '081245311298', 'hiro76', 'hiro#5110', 'hiro_339', 'ktm_hiro.pdf', 'twibbon_hiro.png', 'L', 'Approved', NOW(), NOW(), NULL),
('saki.azizah@gmail.com', 'Saki Azizah', '2002-04-20', 'Mahasiswa', 'Universitas Trisakti', 'Instagram', '081277512920', 'saki92', 'saki#2371', 'saki_982', 'ktm_saki.pdf', 'twibbon_saki.png', 'P', 'Approved', NOW(), NOW(), NULL),
('akihiko.khalid@gmail.com', 'Akihiko Khalid', '2004-06-08', 'Mahasiswa', 'Universitas Gunadarma', 'Website', '081290917201', 'aki10', 'aki#4001', 'aki_771', 'ktm_aki.pdf', 'twibbon_aki.png', 'L', 'Approved', NOW(), NOW(), NULL),
('rina.nakagawa@gmail.com', 'Rina Nakagawa', '2003-05-25', 'Mahasiswa', 'Universitas Mercu Buana', 'Instagram', '081249718230', 'rina88', 'rina#7123', 'rina_772', 'ktm_rina.pdf', 'twibbon_rina.png', 'P', 'Approved', NOW(), NOW(), NULL),
('yuto.wahyu@gmail.com', 'Yuto Wahyu', '2002-09-30', 'Mahasiswa', 'Universitas Indonesia', 'Teman', '081231987612', 'yuto22', 'yuto#8833', 'yuto_331', 'ktm_yuto.pdf', 'twibbon_yuto.png', 'L', 'Approved', NOW(), NOW(), NULL),
('ayaka.suryani@gmail.com', 'Ayaka Suryani', '2005-02-24', 'Mahasiswa', 'Politeknik Negeri Jakarta', 'Instagram', '081244332200', 'ayaka70', 'ayaka#5512', 'ayaka_687', 'ktm_ayaka.pdf', 'twibbon_ayaka.png', 'P', 'Approved', NOW(), NOW(), NULL);

INSERT INTO "User" (
    Email, Full_Name, Birth_Date, Pendidikan, Nama_Sekolah, Entry_Source,
    Phone_Number, ID_Line, ID_Discord, ID_Instagram, KTM_Key, Twibbon_Key,
    Jenis_Kelamin, Registration_Status, Created_At, Updated_At, Media_ID
) VALUES
('rika.sugimoto@gmail.com', 'Rika Sugimoto', '2004-06-02', 'Mahasiswa', 'Universitas Indonesia', 'Instagram', '081289334521', 'rika90', 'rika#1833', 'rika_911', 'ktm_rika.pdf', 'twibbon_rika.png', 'P', 'Approved', NOW(), NOW(), NULL),
('takumi.hartono@gmail.com', 'Takumi Hartono', '2003-08-28', 'Mahasiswa', 'Institut Teknologi Bandung', 'Teman', '081277721510', 'takumi12', 'takumi#7701', 'takumi_311', 'ktm_takumi.pdf', 'twibbon_takumi.png', 'L', 'Approved', NOW(), NOW(), NULL),
('hina.ramadhani@gmail.com', 'Hina Ramadhani', '2005-01-09', 'Mahasiswa', 'Universitas Airlangga', 'Instagram', '081244913420', 'hina29', 'hina#4121', 'hina_551', 'ktm_hina2.pdf', 'twibbon_hina2.png', 'P', 'Approved', NOW(), NOW(), NULL),
('ariel.kanazawa@gmail.com', 'Ariel Kanazawa', '2002-11-16', 'Mahasiswa', 'Universitas Gadjah Mada', 'Website', '081232671223', 'ariel88', 'ariel#9000', 'ariel_220', 'ktm_ariel.pdf', 'twibbon_ariel.png', 'L', 'Approved', NOW(), NOW(), NULL),
('mei.shirakawa@gmail.com', 'Mei Shirakawa', '2003-05-19', 'Mahasiswa', 'Universitas Telkom', 'Instagram', '081264321551', 'mei32', 'mei#5671', 'mei_009', 'ktm_mei3.pdf', 'twibbon_mei3.png', 'P', 'Approved', NOW(), NOW(), NULL),
('keito.nugroho@gmail.com', 'Keito Nugroho', '2004-12-11', 'Mahasiswa', 'IPB University', 'Teman', '081251893410', 'keito91', 'keito#3914', 'keito_779', 'ktm_keito.pdf', 'twibbon_keito.png', 'L', 'Approved', NOW(), NOW(), NULL),
('sakura.putri@gmail.com', 'Sakura Putri', '2002-09-08', 'Mahasiswa', 'BINUS University', 'Instagram', '081262911783', 'sakura15', 'sakura#1188', 'sakura_631', 'ktm_sakurap.pdf', 'twibbon_sakurap.png', 'P', 'Approved', NOW(), NOW(), NULL),
('daichi.prasetyo@gmail.com', 'Daichi Prasetyo', '2003-04-03', 'Mahasiswa', 'Universitas Diponegoro', 'Instagram', '081244981761', 'daichi98', 'daichi#7810', 'daichi_521', 'ktm_daichi.pdf', 'twibbon_daichi.png', 'L', 'Approved', NOW(), NOW(), NULL),
('kana.andira@gmail.com', 'Kana Andira', '2004-02-10', 'Mahasiswa', 'Universitas Negeri Surabaya', 'Website', '081276517221', 'kana22', 'kana#2233', 'kana_182', 'ktm_kana.pdf', 'twibbon_kana.png', 'P', 'Approved', NOW(), NOW(), NULL),
('sho.baskara@gmail.com', 'Sho Baskara', '2005-07-17', 'Mahasiswa', 'Universitas Hasanuddin', 'Teman', '081241882132', 'sho73', 'sho#2210', 'sho_993', 'ktm_sho.pdf', 'twibbon_sho.png', 'L', 'Approved', NOW(), NOW(), NULL),
('ayane.firdaus@gmail.com', 'Ayane Firdaus', '2003-10-04', 'Mahasiswa', 'Universitas Brawijaya', 'Instagram', '081256813552', 'ayane122', 'ayane#4411', 'ayane_801', 'ktm_ayane.pdf', 'twibbon_ayane.png', 'P', 'Approved', NOW(), NOW(), NULL),
('reiji.kautsar@gmail.com', 'Reiji Kautsar', '2002-04-29', 'Mahasiswa', 'Universitas Negeri Jakarta', 'Teman', '081233769010', 'reiji88', 'reiji#5522', 'reiji_421', 'ktm_reiji.pdf', 'twibbon_reiji.png', 'L', 'Approved', NOW(), NOW(), NULL),
('natsu.ramawati@gmail.com', 'Natsu Ramawati', '2004-01-14', 'Mahasiswa', 'Universitas Mercu Buana', 'Website', '081242922112', 'natsu44', 'natsu#9781', 'natsu_664', 'ktm_natsu.pdf', 'twibbon_natsu.png', 'P', 'Approved', NOW(), NOW(), NULL),
('yoshio.firmansyah@gmail.com', 'Yoshio Firmansyah', '2002-08-02', 'Mahasiswa', 'Universitas Trisakti', 'Instagram', '081243881011', 'yoshio92', 'yoshio#7431', 'yoshio_881', 'ktm_yoshio.pdf', 'twibbon_yoshio.png', 'L', 'Approved', NOW(), NOW(), NULL),
('ami.naufalia@gmail.com', 'Ami Naufalia', '2005-06-21', 'Mahasiswa', 'Politeknik Negeri Jakarta', 'Instagram', '081276512900', 'ami19', 'ami#4022', 'ami_119', 'ktm_ami.pdf', 'twibbon_ami.png', 'P', 'Approved', NOW(), NOW(), NULL),
('haruto.sutanto@gmail.com', 'Haruto Sutanto', '2003-12-19', 'Mahasiswa', 'ITS Surabaya', 'Website', '081283199221', 'haruto71', 'haruto#0099', 'haruto_822', 'ktm_haruto.pdf', 'twibbon_haruto.png', 'L', 'Approved', NOW(), NOW(), NULL),
('yui.herlina@gmail.com', 'Yui Herlina', '2004-09-11', 'Mahasiswa', 'Universitas Udayana', 'Teman', '081298631211', 'yui55', 'yui#8110', 'yui_511', 'ktm_yui.pdf', 'twibbon_yui.png', 'P', 'Approved', NOW(), NOW(), NULL),
('kaito.syahreza@gmail.com', 'Kaito Syahreza', '2002-02-05', 'Mahasiswa', 'Universitas Andalas', 'Instagram', '081211923443', 'kaito21', 'kaito#7181', 'kaito_577', 'ktm_kaito.pdf', 'twibbon_kaito.png', 'L', 'Approved', NOW(), NOW(), NULL),
('maria.kinoshita@gmail.com', 'Maria Kinoshita', '2003-03-28', 'Mahasiswa', 'Universitas Sam Ratulangi', 'Instagram', '081274322110', 'maria81', 'maria#9099', 'maria_711', 'ktm_maria.pdf', 'twibbon_maria.png', 'P', 'Approved', NOW(), NOW(), NULL),
('rin.kurniawan@gmail.com', 'Rin Kurniawan', '2004-12-04', 'Mahasiswa', 'Universitas Gunadarma', 'Website', '081243719901', 'rin10', 'rin#3092', 'rin_271', 'ktm_rin3.pdf', 'twibbon_rin3.png', 'L', 'Approved', NOW(), NOW(), NULL),
('satsuki.anggraini@gmail.com', 'Satsuki Anggraini', '2005-06-15', 'Mahasiswa', 'Universitas Negeri Malang', 'Instagram', '081293215671', 'satsuki33', 'satsuki#7700', 'satsuki_111', 'ktm_satsuki.pdf', 'twibbon_satsuki.png', 'P', 'Approved', NOW(), NOW(), NULL),
('kyo.nasrullah@gmail.com', 'Kyo Nasrullah', '2003-05-27', 'Mahasiswa', 'Universitas Sriwijaya', 'Teman', '081234664123', 'kyo90', 'kyo#4083', 'kyo_717', 'ktm_kyo.pdf', 'twibbon_kyo.png', 'L', 'Approved', NOW(), NOW(), NULL),
('hinae.lestari@gmail.com', 'Hinae Lestari', '2002-11-24', 'Mahasiswa', 'Universitas Pancasila', 'Website', '081252664122', 'hinae87', 'hinae#1199', 'hinae_997', 'ktm_hinae.pdf', 'twibbon_hinae.png', 'P', 'Approved', NOW(), NOW(), NULL),
('junpei.rahardian@gmail.com', 'Junpei Rahardian', '2003-04-09', 'Mahasiswa', 'Universitas Esa Unggul', 'Instagram', '081234899213', 'junpei55', 'junpei#6421', 'junpei_888', 'ktm_junpei.pdf', 'twibbon_junpei.png', 'L', 'Approved', NOW(), NOW(), NULL),
('karina.minamoto@gmail.com', 'Karina Minamoto', '2004-07-03', 'Mahasiswa', 'Politeknik Elektronika Negeri Surabaya', 'Instagram', '081277910221', 'karina66', 'karina#7491', 'karina_102', 'ktm_karina.pdf', 'twibbon_karina.png', 'P', 'Approved', NOW(), NOW(), NULL),
('luca.adiwijaya@gmail.com', 'Luca Adiwijaya', '2002-05-21', 'Mahasiswa', 'Universitas Telkom', 'Teman', '081213451201', 'luca72', 'luca#0090', 'luca_100', 'ktm_luca.pdf', 'twibbon_luca.png', 'L', 'Approved', NOW(), NOW(), NULL),
('eriko.damayanti@gmail.com', 'Eriko Damayanti', '2003-01-16', 'Mahasiswa', 'Universitas Jember', 'Instagram', '081243291177', 'eriko18', 'eriko#2022', 'eriko_611', 'ktm_eriko.pdf', 'twibbon_eriko.png', 'P', 'Approved', NOW(), NOW(), NULL),
('ruito.hakim@gmail.com', 'Ruito Hakim', '2005-03-09', 'Mahasiswa', 'Universitas Negeri Yogyakarta', 'Website', '081264729198', 'ruito98', 'ruito#8119', 'ruito_221', 'ktm_ruito.pdf', 'twibbon_ruito.png', 'L', 'Approved', NOW(), NOW(), NULL),
('minato.rahardi@gmail.com', 'Minato Rahardi', '2003-08-21', 'Mahasiswa', 'Universitas Padjadjaran', 'Teman', '081295611220', 'minato12', 'minato#9988', 'minato_120', 'ktm_minato.pdf', 'twibbon_minato.png', 'L', 'Approved', NOW(), NOW(), NULL),
('aya.kusumawati@gmail.com', 'Aya Kusumawati', '2002-06-26', 'Mahasiswa', 'Universitas Islam Indonesia', 'Instagram', '081243558612', 'aya10', 'aya#7212', 'aya_186', 'ktm_aya.pdf', 'twibbon_aya.png', 'P', 'Approved', NOW(), NOW(), NULL),
('takeru.fauzan@gmail.com', 'Takeru Fauzan', '2005-04-10', 'Mahasiswa', 'Universitas Bina Nusantara', 'Instagram', '081243349812', 'takeru73', 'takeru#3011', 'takeru_566', 'ktm_takeru.pdf', 'twibbon_takeru.png', 'L', 'Approved', NOW(), NOW(), NULL),
('sakurae.riyadi@gmail.com', 'Sakurae Riyadi', '2004-10-19', 'Mahasiswa', 'Universitas Pendidikan Indonesia', 'Website', '081233828110', 'sakurae44', 'sakurae#0292', 'sakurae_772', 'ktm_sakurae.pdf', 'twibbon_sakurae.png', 'P', 'Approved', NOW(), NOW(), NULL),
('sora.firmanto@gmail.com', 'Sora Firmanto', '2002-12-25', 'Mahasiswa', 'President University', 'Teman', '081277610292', 'sora81', 'sora#8117', 'sora_701', 'ktm_sora.pdf', 'twibbon_sora.png', 'L', 'Approved', NOW(), NOW(), NULL),
('kanae.yuliana@gmail.com', 'Kanae Yuliana', '2003-02-12', 'Mahasiswa', 'Universitas Gunadarma', 'Instagram', '081288221122', 'kanae42', 'kanae#1902', 'kanae_661', 'ktm_kanae.pdf', 'twibbon_kanae.png', 'P', 'Approved', NOW(), NOW(), NULL),
('hiroto.rakhman@gmail.com', 'Hiroto Rakhman', '2004-01-05', 'Mahasiswa', 'Universitas Negeri Jakarta', 'Instagram', '081247611220', 'hiroto77', 'hiroto#1822', 'hiroto_711', 'ktm_hiroto.pdf', 'twibbon_hiroto.png', 'L', 'Approved', NOW(), NOW(), NULL),
('nami.putrawati@gmail.com', 'Nami Putrawati', '2005-09-12', 'Mahasiswa', 'Universitas Padjadjaran', 'Website', '081243921191', 'nami93', 'nami#2881', 'nami_397', 'ktm_nami.pdf', 'twibbon_nami.png', 'P', 'Approved', NOW(), NOW(), NULL),
('kaisen.mulyana@gmail.com', 'Kaisen Mulyana', '2003-06-20', 'Mahasiswa', 'Universitas Telkom', 'Instagram', '081299112822', 'kaisen10', 'kaisen#1141', 'kaisen_802', 'ktm_kaisen.pdf', 'twibbon_kaisen.png', 'L', 'Approved', NOW(), NOW(), NULL),
('airin.dwi@gmail.com', 'Airin Dwi', '2002-03-11', 'Mahasiswa', 'Universitas Airlangga', 'Teman', '081244653910', 'airin18', 'airin#4092', 'airin_015', 'ktm_airin.pdf', 'twibbon_airin.png', 'P', 'Approved', NOW(), NOW(), NULL),
('rinae.susilawati@gmail.com', 'Rinae Susilawati', '2003-07-06', 'Mahasiswa', 'Universitas Muhammadiyah Malang', 'Instagram', '081244762988', 'rinae72', 'rinae#1981', 'rinae_991', 'ktm_rinae.pdf', 'twibbon_rinae.png', 'P', 'Approved', NOW(), NOW(), NULL),
('yuji.wibisana@gmail.com', 'Yuji Wibisana', '2004-12-18', 'Mahasiswa', 'Universitas Brawijaya', 'Teman', '081249611212', 'yuji99', 'yuji#5220', 'yuji_551', 'ktm_yuji.pdf', 'twibbon_yuji.png', 'L', 'Approved', NOW(), NOW(), NULL),
('marina.hermawan@gmail.com', 'Marina Hermawan', '2005-06-09', 'Mahasiswa', 'Universitas Gunadarma', 'Website', '081222143412', 'marina54', 'marina#6541', 'marina_802', 'ktm_marina.pdf', 'twibbon_marina.png', 'P', 'Approved', NOW(), NOW(), NULL),
('tsubasa.kurnia@gmail.com', 'Tsubasa Kurnia', '2003-10-12', 'Mahasiswa', 'Universitas Negeri Yogyakarta', 'Instagram', '081231299761', 'tsubasa73', 'tsubasa#7719', 'tsubasa_301', 'ktm_tsubasa.pdf', 'twibbon_tsubasa.png', 'L', 'Approved', NOW(), NOW(), NULL),
('harumi.prameswari@gmail.com', 'Harumi Prameswari', '2002-02-28', 'Mahasiswa', 'Universitas Sebelas Maret', 'Teman', '081233721012', 'harumi88', 'harumi#9821', 'harumi_133', 'ktm_harumi.pdf', 'twibbon_harumi.png', 'P', 'Approved', NOW(), NOW(), NULL);

DELETE FROM admin.event_participant;

INSERT INTO Event_Participant (
    Date_Added, Payment_Proof, Payment_Verification, Bundling,
    Paid_For_User, User_ID, Event_ID
)
SELECT
    NOW() - (random() * INTERVAL '45 days') AS Date_Added,
    'payment_' || User_ID || '.pdf',
    (ARRAY['Verified', 'Pending', 'Rejected'])[floor(random() * 3) + 1],
    (ARRAY['None', 'Kaos', 'Hoodie', 'Merchpack'])[floor(random() * 4) + 1],
    NULL,
    User_ID,
    CASE
        WHEN User_ID BETWEEN 1 AND 10 THEN 1
        WHEN User_ID BETWEEN 11 AND 19 THEN 2
        WHEN User_ID BETWEEN 20 AND 67 THEN 3
        WHEN User_ID BETWEEN 68 AND 103 THEN 4
        WHEN User_ID BETWEEN 104 AND 124 THEN 5
    END AS Event_ID
FROM generate_series(1,124) AS User_ID;

WITH team_names AS (
    SELECT gs,
        (ARRAY[
            'Soltera','Zyrex','Nexara','ReVix','Valora','Vyral','Luxion','Ravager','Synkro','Zephra',
            'Voxal','Ophyria','Asterion','Havocore','Xalvion','Astralyze','Cylaris','Ignisia','Stratix',
            'Novatrix','Evolux','Kyvero','Fluxcore','Zerith','Spectron','Helion','Arcline','Kryptex',
            'Vitron','Cryllex','Zenterra','Blazara','Neovex','Mythix','Velzion','Solflare','Kryval',
            'Hydrax','Synerra','Nexalis','Helixor','Vorazen','Zentra','Revora','Avalys','Axion',
            'Devolux','Stormara','Cyverra','Arionyx','Tenebra','Velsari','Erevox','Radiar'
        ])[gs] AS name
    FROM generate_series(1, 35) gs
)
INSERT INTO admin.Team (
    Team_Name, Team_Code, Max_Member, Payment_Proof,
    Verifying_Status, Verifying_Error, Created_At, Updated_At, Event_ID
)
SELECT
    name,
    'T-' || LPAD(gs::text, 3, '0'),
    3,
    'proof_team_' || gs || '.pdf',
    'Verified',
    NULL,
    NOW(),
    NOW(),
    CASE
        WHEN gs BETWEEN 1 AND 16 THEN 3   -- HackToday
        WHEN gs BETWEEN 17 AND 28 THEN 4  -- MineToday
        WHEN gs BETWEEN 29 AND 35 THEN 5  -- GameToday
    END AS Event_ID
FROM team_names;

INSERT INTO admin.team (team_name, team_code, max_member, verifying_status, event_id)
VALUES 
('Solo UX Team', 'T-036', 1, 'Pending', 1),
('Solo CP Team', 'T-037', 1, 'Pending', 2);


WITH pool AS (
    SELECT
        User_ID,
        CASE
            WHEN User_ID BETWEEN 20 AND 67 THEN 1 + floor((User_ID - 20) / 3)  -- 16 teams
            WHEN User_ID BETWEEN 68 AND 103 THEN 17 + floor((User_ID - 68) / 3) -- 12 teams
            WHEN User_ID BETWEEN 104 AND 124 THEN 29 + floor((User_ID - 104) / 3) -- 7 teams
        END AS Team_ID
    FROM generate_series(20,124) AS User_ID
)
INSERT INTO Team_Member (
    Member_Role, Kartu_ID, Verification_Error, User_ID, Team_ID
)
SELECT
    CASE WHEN ROW_NUMBER() OVER (PARTITION BY Team_ID ORDER BY User_ID) = 1
         THEN 'Leader' ELSE 'Member' END,
    'kartu_user_' || User_ID || '.pdf',
    NULL,
    User_ID,
    Team_ID
FROM pool
ORDER BY Team_ID, User_ID;

UPDATE Team t
SET Team_Member_ID = tm.Team_Member_ID
FROM Team_Member tm
WHERE t.Team_ID = tm.Team_ID AND tm.Member_Role = 'Leader';


INSERT INTO User_Identity (
    Email, Identity_Provider, Hash, Verifying_Status,
    Verifying_Token, Verifying_Token_Expiration,
    Password_Recovery_Token, Password_Recovery_Token_Expiration,
    Created_At, Updated_At, User_ID
)
SELECT
    u.Email,
    'credential',
    md5(u.Email) AS Hash,
    (ARRAY['Verified', 'Verified', 'Verified', 'Verified', 'Verified', 'Verified', 'Verified', 'Pending', 'Pending', 'Rejected'])[floor(random()*10)+1],
    md5('verify_' || u.Email),
    NOW() + INTERVAL '30 days',
    CASE WHEN random() < 0.3 THEN md5('recover_' || u.Email) ELSE NULL END,
    CASE WHEN random() < 0.3 THEN NOW() + INTERVAL '7 days' ELSE NULL END,
    NOW(),
    NOW(),
    u.User_ID
FROM "User" u
ORDER BY u.User_ID;

INSERT INTO Session (
    Expires, Data, User_ID
)
SELECT
    NOW() + INTERVAL '7 days',
    'session_data_for_user_' || User_ID,
    User_ID
FROM "User";

INSERT INTO Announcement (
    Title, Description, Author, Created_At, Updated_At,
    Competition, Event_ID, User_ID
)
VALUES
-- CPToday
('Informasi Teknis Penyisihan CP', 'Guidebook terbaru telah dirilis, silakan cek situs resmi.', 'Admin', NOW(), NOW(), 'CPToday', 1, 1),
('Pengumuman Finalis CP', 'Daftar finalis akan diumumkan pada pukul 19.00 WIB.', 'Admin', NOW(), NOW(), 'CPToday', 1, 2),
-- UXToday
('Brief Desain UXToday', 'Pastikan desain mengikuti standar prototyping wajib.', 'Admin', NOW(), NOW(), 'UXToday', 2, 3),
('Pengumuman Finalis UXToday', 'Evaluasi telah selesai, cek daftar finalis di dashboard.', 'Admin', NOW(), NOW(), 'UXToday', 2, 4),
-- HackToday
('Rules Capture The Flag', 'Soal akan tersedia pada hari-H melalui platform resmi.', 'Admin', NOW(), NOW(), 'HackToday', 3, 5),
('Pengumuman Top Scorer HackToday', 'Selamat kepada peserta dengan score tertinggi.', 'Admin', NOW(), NOW(), 'HackToday', 3, 6),
-- MineToday
('Dataset Final MineToday', 'Dataset final telah dirilis dalam format CSV dan Parquet.', 'Admin', NOW(), NOW(), 'MineToday', 4, 7),
('Pengumuman Finalist MineToday', 'Model terbaik akan diumumkan malam ini.', 'Admin', NOW(), NOW(), 'MineToday', 4, 8),
-- GameToday
('Rilis Asset Pack GameToday', 'Asset pack tambahan dapat digunakan secara opsional.', 'Admin', NOW(), NOW(), 'GameToday', 5, 9),
('Pengumuman Pemenang GameToday', 'Juri telah menentukan pemenang berdasarkan gameplay & artstyle.', 'Admin', NOW(), NOW(), 'GameToday', 5, 10);

ALTER TABLE admin.announcement
ALTER COLUMN created_at SET DEFAULT NOW(),
ALTER COLUMN updated_at SET DEFAULT NOW();


INSERT INTO Timeline (
    Timeline_Title, Date, Event, Event_ID
)
VALUES
('Opening Stage', '2025-01-10', 'CPToday', 1),
('Final Stage',   '2025-01-17', 'CPToday', 1),

('Opening Stage', '2025-01-11', 'UXToday', 2),
('Final Stage',   '2025-01-18', 'UXToday', 2),

('Opening Stage', '2025-01-14', 'HackToday', 3),
('Final Stage',   '2025-01-23', 'HackToday', 3),

('Opening Stage', '2025-01-16', 'MineToday', 4),
('Final Stage',   '2025-01-25', 'MineToday', 4),

('Opening Stage', '2025-01-18', 'GameToday', 5),
('Final Stage',   '2025-01-27', 'GameToday', 5);

INSERT INTO Submission (
    Submission_Object, Created_At, Updated_At, Team_ID, Event_ID
)
SELECT
    'submission_team_' || Team_ID || '.zip',
    NOW() - (random() * INTERVAL '10 days'),
    NOW(),
    Team_ID,
    Event_ID
FROM Team;

INSERT INTO Media (
    Name, Media_Grouping, Type, Created_At, Updated_At, Uploader, Event_ID, User_ID
)
VALUES
('poster_cptoday.png', 'Poster', 'Image', NOW(), NOW(), 'System', 1, NULL),
('twibbon_cptoday.png', 'Twibbon', 'Image', NOW(), NOW(), 'System', 1, NULL),

('poster_uxtoday.png', 'Poster', 'Image', NOW(), NOW(), 'System', 2, NULL),
('twibbon_uxtoday.png', 'Twibbon', 'Image', NOW(), NOW(), 'System', 2, NULL),

('poster_hacktoday.png', 'Poster', 'Image', NOW(), NOW(), 'System', 3, NULL),
('twibbon_hacktoday.png', 'Twibbon', 'Image', NOW(), NOW(), 'System', 3, NULL),

('poster_minetoday.png', 'Poster', 'Image', NOW(), NOW(), 'System', 4, NULL),
('twibbon_minetoday.png', 'Twibbon', 'Image', NOW(), NOW(), 'System', 4, NULL),

('poster_gametoday.png', 'Poster', 'Image', NOW(), NOW(), 'System', 5, NULL),
('twibbon_gametoday.png', 'Twibbon', 'Image', NOW(), NOW(), 'System', 5, NULL);


--Dari siniii

ALTER TABLE timeline
    DROP COLUMN event;

ALTER TABLE Team
    DROP CONSTRAINT fk_team_teammember;

ALTER TABLE Team
    DROP COLUMN Team_Member_ID;

ALTER TABLE "User"
    DROP CONSTRAINT fk_user_media,
    DROP COLUMN Media_ID;

WITH ep AS (
    SELECT
        ep.Participant_ID,
        ep.User_ID,
        ep.Event_ID,
        ep.Date_Added,
        ep.Payment_Proof,
        ep.Payment_Verification,
        u.Full_Name
    FROM Event_Participant ep
    JOIN "User" u ON u.User_ID = ep.User_ID
    WHERE NOT EXISTS (
        SELECT 1
        FROM Team_Member tm
        JOIN Team t ON t.Team_ID = tm.Team_ID
        WHERE tm.User_ID = ep.User_ID
          AND t.Event_ID = ep.Event_ID
    )
)
INSERT INTO Team (
    Team_Name,
    Team_Code,
    Max_Member,
    Payment_Proof,
    Verifying_Status,
    Verifying_Error,
    Created_At,
    Updated_At,
    Event_ID
)
SELECT
    e.Full_Name,
    'IND-' || e.User_ID::text,
    1,
    e.Payment_Proof,
    e.Payment_Verification,
    NULL,
    COALESCE(e.Date_Added::timestamp, NOW()),
    COALESCE(e.Date_Added::timestamp, NOW()),
    e.Event_ID
FROM ep e;

WITH ep AS (
    SELECT
        ep.User_ID,
        ep.Event_ID
    FROM Event_Participant ep
    WHERE NOT EXISTS (
        SELECT 1
        FROM Team_Member tm
        JOIN Team t ON t.Team_ID = tm.Team_ID
        WHERE tm.User_ID = ep.User_ID
          AND t.Event_ID = ep.Event_ID
    )
)
INSERT INTO Team_Member (
    Member_Role,
    Kartu_ID,
    Verification_Error,
    User_ID,
    Team_ID
)
SELECT
    'Leader' AS Member_Role,
    NULL    AS Kartu_ID,
    NULL    AS Verification_Error,
    e.User_ID,
    t.Team_ID
FROM ep e
JOIN Team t
  ON t.Team_Code = 'IND-' || e.User_ID::text
 AND t.Event_ID = e.Event_ID;

ALTER TABLE "User"
    ADD COLUMN Password_Hash VARCHAR(255);

UPDATE "User" u
SET Password_Hash = ui.Hash
FROM User_Identity ui
WHERE ui.User_ID = u.User_ID;

DROP TABLE User_Identity;
DROP TABLE Session;
DROP TABLE Event_Participant;

ALTER TABLE Team_Member
    ADD CONSTRAINT uq_team_member_user UNIQUE (User_ID);

-- 1) Hapus kolom Verification_Error di Team_Member
ALTER TABLE Team_Member
    DROP COLUMN Verification_Error;

-- 2) Hapus kolom Verifying_Error di Team
ALTER TABLE Team
    DROP COLUMN Verifying_Error;

-- 3) Hapus kolom Author di Announcement
ALTER TABLE Announcement
    DROP COLUMN Author;

-- 4) Hapus kolom Uploader di Media
ALTER TABLE Media
    DROP COLUMN Uploader;

-- 5) Hapus kolom Max_Noncompetition_Participant di Event
ALTER TABLE Event
    DROP COLUMN Max_Noncompetition_Participant;

-- 6) Hapus kolom Event_Type di Event
ALTER TABLE Event
    DROP COLUMN Event_Type;

ALTER TABLE Event
    DROP CONSTRAINT FK_Event_Media,
    DROP COLUMN Media_ID;

-- Cek apakah ada foreign key, kemudian drop
ALTER TABLE Media
    DROP CONSTRAINT IF EXISTS media_user_id_fkey;

-- Setelah FK dilepas, hapus kolom User_ID
ALTER TABLE Media
    DROP COLUMN IF EXISTS User_ID;

ALTER TABLE Announcement
    DROP COLUMN IF EXISTS Competition;

-- Hapus FK jika ada
ALTER TABLE Announcement
    DROP CONSTRAINT IF EXISTS announcement_user_id_fkey;

-- Hapus kolom User_ID
ALTER TABLE Announcement
    DROP COLUMN IF EXISTS User_ID;

INSERT INTO Submission (
    Submission_Object,
    Created_At,
    Updated_At,
    Team_ID,
    Event_ID
)
SELECT
    'submission_team_' || t.Team_ID || '.zip',
    NOW() - (random() * INTERVAL '5 days'),
    NOW(),
    t.Team_ID,
    t.Event_ID
FROM Team t
LEFT JOIN Submission s ON s.Team_ID = t.Team_ID
WHERE t.Team_Code LIKE 'IND-%'
  AND s.Team_ID IS NULL;

UPDATE admin."User"
SET registration_status = 'verified'
WHERE LOWER(registration_status) = 'approved';





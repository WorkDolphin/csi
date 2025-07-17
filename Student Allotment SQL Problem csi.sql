CREATE PROCEDURE AllocateSubjects
AS
BEGIN
    SET NOCOUNT ON;

    -- Clear previous data
    DELETE FROM Allotments;
    DELETE FROM UnallotedStudents;

    -- Temp table to hold ordered student list
    DECLARE @StudentId BIGINT;

    DECLARE student_cursor CURSOR FOR
        SELECT StudentId
        FROM StudentDetails
        ORDER BY GPA DESC;

    OPEN student_cursor;
    FETCH NEXT FROM student_cursor INTO @StudentId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Pref INT = 1;
        DECLARE @SubjectId VARCHAR(10);
        DECLARE @Allocated BIT = 0;

        WHILE @Pref <= 5 AND @Allocated = 0
        BEGIN
            SELECT TOP 1 @SubjectId = SubjectId
            FROM StudentPreference
            WHERE StudentId = @StudentId AND Preference = @Pref;

            IF @SubjectId IS NOT NULL
            BEGIN
                -- Check seat availability
                IF EXISTS (
                    SELECT 1
                    FROM SubjectDetails
                    WHERE SubjectId = @SubjectId AND RemainingSeats > 0
                )
                BEGIN
                    -- Allot and update seat count
                    INSERT INTO Allotments(SubjectId, StudentId)
                    VALUES (@SubjectId, @StudentId);

                    UPDATE SubjectDetails
                    SET RemainingSeats = RemainingSeats - 1
                    WHERE SubjectId = @SubjectId;

                    SET @Allocated = 1;
                END
            END

            SET @Pref = @Pref + 1;
        END

        -- If not allotted
        IF @Allocated = 0
        BEGIN
            INSERT INTO UnallotedStudents(StudentId)
            VALUES (@StudentId);
        END

        FETCH NEXT FROM student_cursor INTO @StudentId;
    END

    CLOSE student_cursor;
    DEALLOCATE student_cursor;
END;



--for execution
EXEC AllocateSubjects;

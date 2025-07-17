CREATE PROCEDURE HandleSubjectChange
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StudentId VARCHAR(50), @RequestedSubjectId VARCHAR(50), @CurrentSubjectId VARCHAR(50);

    DECLARE request_cursor CURSOR FOR
        SELECT StudentId, SubjectId
        FROM SubjectRequest;

    OPEN request_cursor;
    FETCH NEXT FROM request_cursor INTO @StudentId, @RequestedSubjectId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Get current active subject (if any)
        SELECT @CurrentSubjectId = SubjectId
        FROM SubjectAllotments
        WHERE StudentId = @StudentId AND Is_valid = 1;

        -- Case 1: Student not found in SubjectAllotments (insert as valid)
        IF @CurrentSubjectId IS NULL
        BEGIN
            INSERT INTO SubjectAllotments(StudentId, SubjectId, Is_valid)
            VALUES (@StudentId, @RequestedSubjectId, 1);
        END
        ELSE IF @CurrentSubjectId != @RequestedSubjectId
        BEGIN
            -- Invalidate current subject
            UPDATE SubjectAllotments
            SET Is_valid = 0
            WHERE StudentId = @StudentId AND Is_valid = 1;

            -- Insert new subject as valid
            INSERT INTO SubjectAllotments(StudentId, SubjectId, Is_valid)
            VALUES (@StudentId, @RequestedSubjectId, 1);
        END
        -- Else: Same subject already active → Do nothing

        FETCH NEXT FROM request_cursor INTO @StudentId, @RequestedSubjectId;
    END

    CLOSE request_cursor;
    DEALLOCATE request_cursor;
END;

--  for execution

EXEC HandleSubjectChange;

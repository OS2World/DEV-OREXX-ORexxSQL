/*--------------------------------------------------------------------------*/
/*                                                                          */
/*  ORexx/SQL Object Framework v1.0                                         */
/*                                                                          */
/*  Copyright (C) 1997 - 1998, John Blumel.                                 */
/*                                                                          */
/*  This library is free software; you can redistribute it and/or           */
/*  modify it under the terms of the GNU Library General Public             */
/*  License as published by the Free Software Foundation; either            */
/*  version 2 of the License, or (at your option) any later version.        */
/*                                                                          */
/*  This library is distributed in the hope that it will be useful,         */
/*  but WITHOUT ANY WARRANTY; without even the implied warranty of          */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       */
/*  Library General Public License for more details.                        */
/*                                                                          */
/*  You should have received a copy of the GNU Library General Public       */
/*  License along with this library; if not, write to:                      */
/*                                                                          */
/*            Free Foundation, Inc.                                         */
/*            59 Temple Place                                               */
/*            Suite 330                                                     */
/*            Boston, MA  02111-1307  USA                                   */
/*                                                                          */
/*  Contact: jblumel@acm.org                                                */
/*                                                                          */
/*  Thanks to:                                                              */
/*    Mark Hessling for creating the Rexx/SQL interface, without which,     */
/*      this project would literally not have been possible.                */
/*    Rony Flatscher for sharing his ORexx expertise with me and for        */
/*      his advice on the framework architecture.                           */
/*                                                                          */
/*  SQLStream.cls  -  SQLStream class                                       */
/*                                                                          */
/*  Requirements:                                                           */
/*    REXXSQL library . . . . . Rexx/SQL interface by Mark Hessling         */
/*                                http://www.lightlink.com/hessling/        */
/*    SQLConnection.cls . . . . SQLConnection class                         */
/*    SQLTable.cls  . . . . . . SQLTable class                              */
/*    SQLResultTable.cls  . . . SQLResultTable class                        */
/*    SQLStreamSupplier.cls . . SQLStreamSupplier class                     */
/*    SQLError.rtn  . . . . . . SQLError Routine                            */
/*                                                                          */
/*  Notes:                                                                  */
/*    - All methods which require the stream to be open will open it if     */
/*      it is not already open when they are invoked.                       */
/*    - If no input stream is defined, invoking a method which requires     */
/*      a defined input stream will result in an exception being raised.    */
/*                                                                          */
/*--------------------------------------------------------------------------*/
::REQUIRES 'SQLConnection.cls'
::REQUIRES 'SQLTable.cls'
::REQUIRES 'SQLResultTable.cls'
::REQUIRES 'SQLStreamSupplier.cls'
::REQUIRES 'SQLError.rtn'

/*--------------------------------------------------------------------------*/
/* SQLStream Class definition                                               */
/*--------------------------------------------------------------------------*/
::CLASS SQLStream SUBCLASS SQLConnection PUBLIC

/*--------------------------------------------------------------------------*/
/* SQLStream instance variables                                             */
/*--------------------------------------------------------------------------*/
::METHOD inStream ATTRIBUTE PRIVATE
::METHOD outStream ATTRIBUTE PRIVATE

/*--------------------------------------------------------------------------*/
/* SQLStream Instance Methods                                               */
/*--------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------*/
/* ::METHOD Init                                                            */
/*   - Initializes the SQLStream object                                     */
/*   - Argument 1                                                           */
/*      User ID used to login to the database.                              */
/*   - Argument 2                                                           */
/*      Password used to login to the database.                             */
/*   - Argument 3                                                           */
/*      The name of the database to login to.                               */
/*   - Argument 4                                                           */
/*      The name of the database server.                                    */
/*--------------------------------------------------------------------------*/
::METHOD Init
	expose sqlca.
	signal on USER SQLError NAME InitError
    use arg userName, password, database, host

	if (\Var('database')) then database = ''
	if (\Var('host')) then host = ''

	self~inStream = .nil
	self~outStream = .nil

	self~Init:super(userName, password, database, host, 1)

	return

	InitError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD UnInit                                                          */
/*   - This method is automatically invoked when a SQLStream object         */
/*     is destroyed and the SQL connection is dropped.                      */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD UnInit

	if self~connected then self~close
	
/*--------------------------------------------------------------------------*/
/* ::METHOD ArrayIn                                                         */
/*   - Returns an array of stems, indexed by column name, from the          */
/*     specified input stream or. If no input stream is specified, the      */
/*     current stream is used. If no input stream is defined, the NIL       */
/*     object is returned.                                                  */
/*   - Argument 1                                                           */
/*      The maximum number of rows to return from the stream.               */
/*   - Argument 2 (optional)                                                */
/*      A valid SELECT statement which will be used to initialize the       */
/*      input stream.                                                       */
/*--------------------------------------------------------------------------*/
::METHOD ArrayIn
	expose sqlca.
	use arg maxRows, selectStmt
	signal on USER SQLError NAME ArrayInError

	if (\self~connected) then self~open

	if (Var('selectStmt')) then do
		if (self~inStream == .nil) then do
			self~inStream = .SQLResultTable~new(self, selectStmt)~~Open
		end
		else do
			if (self~inStream~Statement <> selectStmt) then do
				self~inStream = .SQLResultTable~new(self, selectStmt)~~Open
			end
			else do
				self~Rewind
			end
		end
	end

	if (self~inStream <> .nil) then do
		if (\Var('maxRows')) then maxRows = 0
		rowSet = .array~new(maxRows)
		rowSet = self~inStream~FetchRowSet(maxRows)
	end
	else do
		sqlca.class = self~class
		sqlca.exception = 'ArrayIn failed -- input stream is undefined'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	return rowSet

	ArrayInError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD ArrayOut                                                        */
/*   - Appends the array contents to the output stream.                     */
/*   - Argument 1                                                           */
/*      A database table name which is used to define the output stream.    */
/*   - Argument 2                                                           */
/*      An array of Stem objects, indexed by column name, containing the    */
/*      the column values to be written to the output stream.               */
/*--------------------------------------------------------------------------*/
::METHOD ArrayOut
	expose sqlca.
	use arg theTable, theRows
	signal on USER SQLError NAME ArrayOutError

	if (\self~connected) then self~open

	if (self~outStream == .nil) then do
		self~outStream = .SQLTable~new(self, theTable)
	end
	else do
		if (self~outStream~TableName <> theTable) then do
			self~outStream = .SQLTable~new(self, theTable)
		end
	end

	do i = 1 to theRows~Items
		self~outStream~Insert(theRows[i])
	end

	return

	ArrayOutError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Close                                                           */
/*   - Closes the stream.                                                   */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Close
	expose sqlca.
	signal on USER SQLError NAME CloseError
	
	self~Close:super
	self~inStream = .nil
	self~outStream = .nil

	return

	CloseError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD LongColumnIn                                                    */
/*   - Used in conjunction with the In method, this method will return      */
/*     all or part of a column from the row last accessed by the In method. */
/*   - Argument 1                                                           */
/*      The name of the column.                                             */
/*   - Argument 2                                                           */
/*      The, 1 based, starting byte from which to retrieve data.            */
/*   - Argument 3                                                           */
/*      The number of bytes to retrieve.                                    */
/*--------------------------------------------------------------------------*/
::METHOD LongColumnIn
	expose sqlca.
    use arg columnName, startPosition, length
	signal on USER SQLError NAME LongColumnInError

	if (\self~connected) then self~open

	if (self~inStream <> .nil) then do
		return self~inStream~GetLongColumnData(columnName, startPosition, length)
	end
	else do
		sqlca.class = self~class
		sqlca.exception = 'LongColumnIn failed -- input stream is undefined'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	LongColumnInError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD LongColumnToFile                                                */
/*   - Used in conjunction with the In method, this method will write all   */
/*     or part of a column from the row last accessed by the In method to   */
/*     an operating system file.                                            */
/*   - Argument 1                                                           */
/*      The name of the column.                                             */
/*   - Argument 2                                                           */
/*      The name of the file to which the data should be written.           */
/*--------------------------------------------------------------------------*/
::METHOD LongColumnToFile
	expose sqlca.
    use arg columnName, outFile
	signal on USER SQLError NAME LongColumnToFileError

	if (\self~connected) then self~open

	if (self~inStream <> .nil) then do
		self~inStream~WriteLongColumnToFile(columnName, outFile)
	end
	else do
		sqlca.class = self~class
		sqlca.exception = 'LongColumnToFile failed -- input stream is undefined'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	return

	LongColumnToFileError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Command                                                         */
/*   - Used to immediately run a SQL statement. This method is intended to  */
/*     primarily support DDL statements and the return of result rows is    */
/*     not supported.                                                       */
/*   - Argument 1                                                           */
/*      Any valid SQL statement.                                            */
/*--------------------------------------------------------------------------*/
::METHOD Command
	expose sqlca.
	use arg sqlStatement
	signal on USER SQLError NAME CommandError

	if (\self~connected) then self~open

	forward class (super)

	CommandError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD CommandWithBind                                                 */
/*   - Performs the same function as the Command method but allows use of   */
/*     bind values with the SQL statment.                                   */
/*   - Argument 1                                                           */
/*      Any valid SQL statement.                                            */
/*   - Argument 2                                                           */
/*      A Stem object containing the bind data types.                       */
/*   - Argument 3                                                           */
/*      A Stem object containing the bind values.                           */
/*--------------------------------------------------------------------------*/
::METHOD CommandWithBind
	expose sqlca.
	use arg sqlStatement
	signal on USER SQLError NAME CommandWithBindError

	if (\self~connected) then self~open

	forward class (super)

	CommandWithBindError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Commit                                                          */
/*   - Invoking this method commits the current transaction.                */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Commit
	expose sqlca.
	signal on USER SQLError NAME CommitError

	if (\self~connected) then self~open

	forward class (super)

	CommitError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD In                                                              */
/*   - Returns the next available row from the input stream as a Stem       */
/*     object indexed by column name.                                       */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD In
	expose sqlca.
	signal on USER SQLError NAME InError

	if (\self~connected) then self~open

	if (self~inStream <> .nil) then do
		return self~inStream~Fetch
	end
	else do
		sqlca.class = self~class
		sqlca.exception = 'In failed -- input stream is undefined'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	return 

	InError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD MakeArray                                                       */
/*   - Returns an array of stems, indexed by column name, from the          */
/*     specified input stream or. If no input stream is specified, the      */
/*     current stream is used. If no input stream is defined, the NIL       */
/*     object is returned.                                                  */
/*   - Argument 1                                                           */
/*      The maximum number of rows to return from the stream.               */
/*   - Argument 2 (optional)                                                */
/*      A valid SELECT statement which will be used to initialize the       */
/*      input stream.                                                       */
/*--------------------------------------------------------------------------*/
::METHOD MakeArray
	expose sqlca.

	forward to (self~ArrayIn)

/*--------------------------------------------------------------------------*/
/* ::METHOD Open                                                            */
/*   - Opens the stream.                                                    */
/*   - Arguments 1 (optional)                                               */
/*      The value 'AUTOCOMMIT'. If supplied values written to the ouput     */
/*      will be committed automatically.                                    */
/*--------------------------------------------------------------------------*/
::METHOD Open
	expose sqlca.
	use arg commitMode
	signal on USER SQLError NAME OpenError

	if (\Var('commitMode') | Translate(commitMode) <> 'AUTOCOMMIT') then do
		self~AutoCommit = 0
	end
	else do
		self~AutoCommit = 1
	end

	self~Open:super

	return

	OpenError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Out                                                             */
/*   - Writes data or queries to the output stream                          */
/*   - Argument 1 -- the Arguments vary depending on the value of the       */
/*     first argumentwhich can be one of the following literal values:      */
/*                                                                          */
/*     QUERY                                                                */
/*     - Argument 2                                                         */
/*        A valid SELECT statement.                                         */
/*                                                                          */
/*     INSERT                                                               */
/*     - Argument 2                                                         */
/*        A database table name.                                            */
/*     - Argument 3                                                         */
/*        A Stem object, indexed by column name, containing the values      */
/*        to be inserted.                                                   */
/*                                                                          */
/*     UPDATE                                                               */
/*     - Argument 2                                                         */
/*        A database table name.                                            */
/*     - Argument 3                                                         */
/*        A Stem object, indexed by column name, containing the values      */
/*        to be inserted.                                                   */
/*     - Argument 4                                                         */
/*        A string specifying the value for the UPDATE's WHERE clause.      */
/*                                                                          */
/*        Note: A condition of 'ALL' must be used to update                 */
/*   	        all rows of a table.                                        */
/*                                                                          */
/*     DELETE                                                               */
/*     - Argument 2                                                         */
/*        A database table name.                                            */
/*     - Argument 3                                                         */
/*        A string specifying the value for the DELETE's WHERE clause.      */
/*                                                                          */
/*        Note: A condition of 'ALL' must be used to delete                 */
/*   	        all rows of a table.                                        */
/*                                                                          */
/*--------------------------------------------------------------------------*/
::METHOD Out
	expose sqlca.
	use arg outputMode
	params = arg(2, 'A')
	signal on USER SQLError NAME OutError

	outputMode = Translate(outputMode)

	if (\self~connected) then self~open

	select
		when (outputMode = 'QUERY') then do
			if (self~inStream == .nil) then do
				self~inStream = .SQLResultTable~new(self, params[1])~~Open
			end
			else do
				if (self~inStream~Statement <> params[1]) then do
					self~inStream = .SQLResultTable~new(self, params[1])~~Open
				end
				else do
					self~inStream~ReOpen
				end
			end
		end
		when (outputMode = 'INSERT' | ,
			  outputMode = 'UPDATE' | ,
			  outputMode = 'DELETE') ,
		then do
			if (self~outStream == .nil) then do
				self~outStream = .SQLTable~new(self, params[1])
			end
			else do
				if (self~outStream~TableName <> theTable) then do
					self~outStream = .SQLTable~new(self, params[1])
				end
			end

			select
				when (outputMode = 'INSERT' ) then do
					self~outStream~Insert(params[2])
				end
				when (outputMode = 'UPDATE') then do
					self~outStream~Update(params[2], params[3])
				end
				when (outputMode = 'DELETE') then do
					self~outStream~Delete(params[2])
				end
			end
		end
		otherwise do
			sqlca.class = self~class
			sqlca.exception = 'Out failed -- output mode 'outputMode' is undefined'
			raise USER SQLError ADDITIONAL (sqlca.~copy)
		end
	end

	return

	OutError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Qualify                                                         */
/*   - Returns the qualified stream name which consists of the following    */
/*     colon (':') separated values:                                        */
/*  		                                                            */
/*                 DBMSName:HostName:Database Name                          */
/*                                                                          */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Qualify
	expose sqlca.
	signal on USER SQLError NAME QualifyError

	if (\self~connected) then self~open

	qualName = self~DBMSName
	if (self~host <> '') then qualName = qualName || ':' || self~host
	if (self~database <> '') then qualName = qualName || ':' || self~database

	return self~DBMSName

	QualifyError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Query                                                           */
/*   - Used with the options which can be specified for Argument 1, this    */
/*     method returns specific information about a SQLStream.               */
/*   - Argument 1.                                                          */
/*      One of the following options:                                       */
/*                                                                          */
/*      LONGLIMIT                                                           */
/*        When this option is used the value of the Rexx/SQL variable       */
/*        LONGLIMIT for this stream will be returned.                       */
/*                                                                          */
/*      SAVESQL                                                             */
/*        When this option is used the value of the Rexx/SQL variable       */
/*        SAVESQL for this stream will be returned.                         */
/*                                                                          */
/*      AUTOCOMMIT                                                          */
/*        When this option is used the value of the Rexx/SQL variable       */
/*        AUTOCOMMIT for this stream will be returned.                      */
/*                                                                          */
/*      IGNORETRUNCATE                                                      */
/*        When this option is used the value of the Rexx/SQL variable       */
/*        IGNORETRUNCATE for this stream will be returned.                  */
/*                                                                          */
/*      NULLSTRINGOUT                                                       */
/*        When this option is used the value of the Rexx/SQL variable       */
/*        NULLSTRINGOUT for this stream will be returned.                   */
/*                                                                          */
/*      NULLSTRINGIN                                                        */
/*        When this option is used the value of the Rexx/SQL variable       */
/*        NULLSTRINGIN for this stream will be returned.                    */
/*                                                                          */
/*      DEBUGLEVEL                                                          */
/*        When this option is used the value of the Rexx/SQL variable       */
/*        DEBUG for this stream will be returned.                           */
/*                                                                          */
/*      SUPPORTSPLACEMARKERS                                                */
/*        When this option is used the value of the Rexx/SQL variable       */
/*        SUPPORTSPLACEMARKERS for this stream will be returned.            */
/*                                                                          */
/*      SUPPORTSDMLROWCOUNT                                                 */
/*        When this option is used the value of the Rexx/SQL variable       */
/*        SUPPORTSDMLROWCOUNT for this stream will be returned.             */
/*                                                                          */
/*      VERSION                                                             */
/*        When this option is used the value of the Rexx/SQL variable       */
/*        VERSION for this stream will be returned.                         */
/*                                                                          */
/*      DATATYPES                                                           */
/*        Returns a Stem object containing the data types appropriate       */
/*        for the database.                                                 */
/*                                                                          */
/*      COLUMNATTRIBUTES                                                    */
/*        Returns a Stem object containing the column attributes            */
/*        appropriate for the database.                                     */
/*                                                                          */
/*      SUPPORTSTRANSACTIONS                                                */
/*        Returns                                                           */
/*         0 = The database does not support transactions.                  */
/*         1 = The database supports transactions.                          */
/*                                                                          */
/*      SUPPORTSGETCOLUMNDATA                                               */
/*        Returns                                                           */
/*         0 = The database does not support the SQLResultTable             */
/*             GetLongColumnData & WriteLongColumnToFile methods.           */
/*         1 = The database does support the SQLResultTable                 */
/*             GetLongColumnData & WriteLongColumnToFile methods.           */
/*                                                                          */
/*      DBMSNAME                                                            */
/*        Returns the name of the database to which the SQLStream object    */
/*        is connected.                                                     */
/*                                                                          */
/*      STATE                                                               */
/*        Returns the current value of SQLCA.                               */
/*                                                                          */
/*      OUTSTATEMENT                                                        */
/*        Returns the last active SQL statement for the output stream,      */
/*        if any.                                                           */
/*                                                                          */
/*      INSTATEMENT                                                         */
/*        Returns the last active SQL statement for the input stream,       */
/*        if any.                                                           */
/*                                                                          */
/*      TABLENAME                                                           */
/*        Returns the last active database table for the output stream,     */
/*        if any.                                                           */
/*                                                                          */
/*      DESCRIBE                                                            */
/*        Returns a Stem object containing information describing the       */
/*        data available from the currently active input stream, if any.    */
/*        For a description of the Stem  object returned, see the           */
/*        Rexx/SQL documentation for the SQLDescribe() function.            */
/*--------------------------------------------------------------------------*/
::METHOD Query
	expose sqlca.
	use arg option
	signal on USER SQLError NAME QueryError

	option = Translate(option)

	select	
		when (option = "LONGLIMIT") then do
			return self~LongLimit
		end
		when (option = "SAVESQL") then do
			return self~SaveSQL
		end
		when (option = "AUTOCOMMIT") then do
			return self~AutoCommit
		end
		when (option = "IGNORETRUNCATE") then do
			return self~IgnoreTruncate
		end
		when (option = "NULLSTRINGOUT") then do
			return self~NullStringOut
		end
		when (option = "NULLSTRINGIN") then do
			return self~NullStringIn
		end
		when (option = "STANDARDPLACEMARKERS") then do
			return self~StandardPlacemarkers
		end
		when (option = "DEBUGLEVEL") then do
			return self~DebugLevel
		end
		when (option = "SUPPORTSPLACEMARKERS") then do
			return self~SupportsPlacemarkers
		end
		when (option = "SUPPORTSDMLROWCOUNT") then do
			return self~SupportsDMLRowCount
		end
		when (option = "VERSION") then do
			return self~Version
		end
		when (option = "DATATYPES") then do
			return self~DataTypes
		end
		when (option = "COLUMNATTRIBUTES") then do
			return self~ColumnAttributes
		end
		when (option = "SUPPORTSTRANSACTIONS") then do
			return self~SupportsTransactions
		end
		when (option = "SUPPORTSGETCOLUMNDATA") then do
			return self~SupportsGetColumnData
		end
		when (option = "DBMSNAME") then do
			return self~DBMSName
		end
		when (option = "STATE") then do
			return self~State
		end
		when (option = "OUTSTATEMENT") then do
			if (self~outStream <> .nil) then do
				return self~outStream~Statement
			end
			else do
				return .nil
			end
		end
		when (option = "INSTATEMENT") then do
			if (self~inStream <> .nil) then do
				return self~inStream~Statement
			end
			else do
				return .nil
			end
		end
		when (option = "TABLENAME") then do
			if (self~outStream <> .nil) then do
				return self~outStream~TableName
			end
			else do
				return .nil
			end
		end
		when (option = "DESCRIBE") then do
			if (self~inStream <> .nil) then do
				return self~inStream~Describe
			end
			else do
				return .nil
			end
		end
		otherwise do
			sqlca.class = self~class
			sqlca.exception = 'Query failed -- option 'option' is undefined'
			raise USER SQLError ADDITIONAL (sqlca.~copy)
		end
	end

	QueryError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Rewind                                                          */
/*   - Returns.                                                             */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Rewind
	expose sqlca.
	signal on USER SQLError NAME RewindError

	if (\self~connected) then self~open

	if (self~inStream <> .nil) then do
		self~inStream~ReOpen
	end
	else do
		sqlca.class = self~class
		sqlca.exception = 'Rewind failed -- input stream is undefined'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	return

	RewindError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Rollback                                                        */
/*   - Invoking this method rolls back the current transaction.             */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Rollback
	expose sqlca.
	signal on USER SQLError NAME RollbackError

	if (\self~connected) then self~open

	forward class (super)

	RollbackError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Supplier                                                        */
/*   - Returns a supplier object for the stream.                            */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Supplier
	expose sqlca.
	use arg selectStmt
	signal on USER SQLError NAME SupplierError

	if (\self~connected) then self~open

	if (self~inStream <> .nil | selectStmt <> '') then do
		if (\Var('selectStmt')) then do
			return .SQLStreamSupplier~new(self)
		end
		else do
			return .SQLStreamSupplier~new(self, selectStmt)
		end
	end
	else do
		sqlca.class = self~class
		sqlca.exception = 'Supplier creation failed -- input stream is undefined'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	SupplierError: raise propagate

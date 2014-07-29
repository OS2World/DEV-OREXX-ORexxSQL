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
/*  SQLConnection.cls  -  SQLConnection class                               */
/*                                                                          */
/*  Requirements:                                                           */
/*    REXXSQL library  . . . . . Rexx/SQL interface by Mark Hessling        */
/*                                http://www.lightlink.com/hessling/        */
/*    SQLObject.cls  . . . . . . SQLObject class                            */
/*                                                                          */
/*--------------------------------------------------------------------------*/
::REQUIRES 'SQLObject.cls'

/*--------------------------------------------------------------------------*/
/* SQLConnection Class definition                                           */
/*--------------------------------------------------------------------------*/
::CLASS SQLConnection SUBCLASS SQLObject PUBLIC

/*--------------------------------------------------------------------------*/
/* SQLResultTable Class variables                                           */
/*--------------------------------------------------------------------------*/
::METHOD defaultConnection CLASS ATTRIBUTE

/*--------------------------------------------------------------------------*/
/* SQLConnection instance variables                                         */
/*--------------------------------------------------------------------------*/
/* For initializing and maintaining connections */
::METHOD connectionName ATTRIBUTE PRIVATE
::METHOD userName ATTRIBUTE PRIVATE
::METHOD password ATTRIBUTE PRIVATE
::METHOD database ATTRIBUTE PRIVATE
::METHOD host ATTRIBUTE PRIVATE
::METHOD connected ATTRIBUTE PRIVATE

/* SQLVariable data */
::METHOD LongLimit ATTRIBUTE
::METHOD SaveSQL ATTRIBUTE
::METHOD AutoCommit ATTRIBUTE
::METHOD IgnoreTruncate ATTRIBUTE
::METHOD NullStringOut ATTRIBUTE
::METHOD NullStringIn ATTRIBUTE
::METHOD connSupportsPlacemarkers ATTRIBUTE PRIVATE
::METHOD connSupportsDMLRowCount ATTRIBUTE PRIVATE
::METHOD DebugLevel ATTRIBUTE

/* SQLGetInfo data */
::METHOD connDataTypes. ATTRIBUTE PRIVATE
::METHOD connColumnAttributes. ATTRIBUTE PRIVATE
::METHOD connSupportsTransactions ATTRIBUTE PRIVATE
::METHOD connSupportsGetColumnData ATTRIBUTE PRIVATE
::METHOD connDBMSName ATTRIBUTE PRIVATE

/*--------------------------------------------------------------------------*/
/* SQLWorkConnection Instance Methods                                       */
/*--------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------*/
/* ::METHOD Init                                                            */
/*   - This method is automatically invoked when the SQLConnection class    */
/*     is sent a NEW message. A SQL connection is created using the         */ 
/*     arguments supplied with the new message NEW and the instance         */ 
/*     variables are initialized.                                           */
/*   - Argument 1                                                           */
/*      User ID used to login to the database.                              */
/*   - Argument 2                                                           */
/*      Password used to login to the database.                             */
/*   - Argument 3                                                           */
/*      The name of the database to login to.                               */
/*   - Argument 4                                                           */
/*      The name of the database server.                                    */
/*   - Argument 5                                                           */
/*      Boolean value indicating whether to defer opening the connection    */
/*                                                                          */
/*--------------------------------------------------------------------------*/
::METHOD Init
	expose sqlca.
    use arg  userName, password, database, host, deferOpen
	signal on USER SQLError NAME InitError

	if (\Var('database')) then database = ''
	if (\Var('host')) then host = ''
	if (\Var('deferOpen') | deferOpen <> 1) then deferOpen = 0

    self~connectionName = 'c' || self~class~instances
    self~userName = userName
    self~password = password
    self~database = database
    self~host = host
	self~connected = 0

	if (\deferOpen) then do
	    self~Open
	end

	self~LongLimit = SQLVariable("LONGLIMIT")
	self~SaveSQL = SQLVariable("SAVESQL")
	self~AutoCommit = SQLVariable("AUTOCOMMIT")
	self~IgnoreTruncate = SQLVariable("IGNORETRUNCATE")
	self~NullStringOut = '<null>'
	self~NullStringIn = '<null>'
	self~connSupportsPlacemarkers = ''
	self~connSupportsDMLRowCount = ''
	self~DebugLevel = SQLVariable("DEBUG")

	dt.0 = ''
	self~connDataTypes. = dt.~copy
	ca.0 = ''
	self~connColumnAttributes. = ca.~copy
    self~connSupportsTransactions = ''
    self~connSupportsGetColumnData = ''
    self~connDBMSName = ''

	return

	InitError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD UnInit                                                          */
/*   - This method is automatically invoked when a SQLConnection object     */
/*     is destroyed and the SQL connection is dropped.                      */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD UnInit

	if self~connected then self~close
    
/*--------------------------------------------------------------------------*/
/* ::METHOD Open                                                            */
/*   - This method opens a database connection using the SQLConnection      */
/*     instance data.                                                       */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Open
	expose sqlca.
	signal on USER SQLError NAME OpenError

	if (\self~connected) then do	
		if (SQLConnect(self~connectionName, ,
					   self~userName, ,
					   self~password, ,
					   self~database, ,
					   self~host) == 0) ,
		then do
			self~connected = 1
		end
		else do
			sqlca.class = self~class
			sqlca.exception = 'Open failed'
			raise USER SQLError ADDITIONAL (sqlca.~copy)
		end
	end

    if (SQLVariable("STANDARDPLACEMARKERS", 1) < 0) then do
		sqlca.class = self~class
		sqlca.exception = 'Open:StandardPlacemarkers failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	return

	OpenError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Close                                                           */
/*   - Closes the database connection if one is open.                       */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Close
	expose sqlca.
	signal on USER SQLError NAME CloseError

	if (self~connected) then do	
		if (SQLDisconnect(self~connectionName) == 0) then do
			self~connected = 0
		end
		else do
			sqlca.class = self~class
			sqlca.exception = 'Close failed'
			raise USER SQLError ADDITIONAL (sqlca.~copy)
		end
	end

	return

	CloseError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD MakeDefault                                                     */
/*   - This method is used to set the connection object as the default      */
/*     connection. The MakeDefault is primarily used by the SQLTable &      */
/*     SQLResultTable classes and you should normally not need to           */
/*     invoke this method.                                                  */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD MakeDefault
	expose sqlca.
	signal on USER SQLError NAME MakeDefaultError

	if (self~connectionName == self~class~defaultConnection) then return

    if (SQLDefault(self~connectionName) <> 0) then do
		sqlca.class = self~class
		sqlca.exception = 'MakeDefault:MakeDefault failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	self~DebugLevel = SQLVariable("DEBUG")

    if (SQLVariable("LONGLIMIT", self~LongLimit) < 0) then do
		sqlca.class = self~class
		sqlca.exception = 'MakeDefault:LongLimit failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

    if (SQLVariable("SAVESQL", self~SaveSQL) < 0) then do
		sqlca.class = self~class
		sqlca.exception = 'MakeDefault:SaveSQL failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

    if (SQLVariable("AUTOCOMMIT", self~AutoCommit) < 0) then do
		sqlca.class = self~class
		sqlca.exception = 'MakeDefault:AutoCommit failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

    if (SQLVariable("IGNORETRUNCATE", self~IgnoreTruncate) < 0) then do
		sqlca.class = self~class
		sqlca.exception = 'MakeDefault:IgnoreTruncate failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

    if (SQLVariable("NULLSTRINGOUT", self~NullStringOut) < 0) then do
		sqlca.class = self~class
		sqlca.exception = 'MakeDefault:NullStringOut failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

    if (SQLVariable("NULLSTRINGIN", self~NullStringIn) < 0) then do
		sqlca.class = self~class
		sqlca.exception = 'MakeDefault:NullStringIn failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

    if (SQLVariable("DEBUG", self~DebugLevel) < 0) then do
		sqlca.class = self~class
		sqlca.exception = 'MakeDefault:DebugLevel failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	self~class~defaultConnection = self~connectionName

	return

	MakeDefaultError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Command                                                         */
/*   - Used to immediately run a SQL statement. This method is intended to  */
/*     primarily support DDL statements and the return of result rows is    */
/*     not supported. (It is intended that SQLTable & SQLResulTable objects */
/*     be used for DML statements.)                                         */
/*   - Argument 1                                                           */
/*      Any valid SQL statement.                                            */
/*--------------------------------------------------------------------------*/
::METHOD Command
	expose sqlca.
    use arg sqlStatement
	signal on USER SQLError NAME CommandError

    self~MakeDefault

    if (SQLCommand("MyStmt", sqlStatement) <> 0) then do
		sqlca.class = self~class
		sqlca.exception = 'Command failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	return

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
    use arg sqlStatement, bindDataTypes., bindValues.
	signal on USER SQLError NAME CommandWithBindError

    self~MakeDefault

    if (SQLCommand("MyStmt", sqlStatement, "bindDataTypes.", "bindValues.") <> 0) then do
		sqlca.class = self~class
		sqlca.exception = 'CommandWithBind failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	return

	CommandWithBindError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Commit                                                          */
/*   - Invoking this method commits the current transaction.                */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Commit
	expose sqlca.
	signal on USER SQLError NAME CommitError

    self~MakeDefault

    if (SQLCommit() <> 0) then do
		sqlca.class = self~class
		sqlca.exception = 'Commit failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	return

	CommitError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD Rollback                                                        */
/*   - Invoking this method rolls back the current transaction.             */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD Rollback
	expose sqlca.
	signal on USER SQLError NAME RollbackError

    self~MakeDefault

    if (SQLRollback() <> 0) then do
		sqlca.class = self~class
		sqlca.exception = 'Rollback failed'
		raise USER SQLError ADDITIONAL (sqlca.~copy)
	end

	return

	RollbackError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD State                                                           */
/*   - Returns the current value of SQLCA.                                  */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD State
	expose sqlca.

	return sqlca.

/*--------------------------------------------------------------------------*/
/* ::METHOD SupportsPlacemarkers                                            */
/*   - Returns the current value of the Rexx/SQL SUPPORTSPLACEMARKERS       */
/*     variable for this connection.                                        */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD SupportsPlacemarkers
	expose sqlca.
	signal on USER SQLError NAME SupportsPlacemarkersError

	if (self~connSupportsPlacemarkers == '') then do
	    self~connSupportsPlacemarkers = SQLVariable("SUPPORTSPLACEMARKERS")
		if (self~connSupportsPlacemarkers < 0) then do
			sqlca.class = self~class
			sqlca.exception = 'SupportsPlacemarkers failed'
			raise USER SQLError ADDITIONAL (sqlca.~copy)
		end
	end

	return self~connSupportsPlacemarkers

	SupportsPlacemarkersError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD SupportsDMLRowCount                                             */
/*   - Returns the current value of the Rexx/SQL SUPPORTSDMLROWCOUNT        */
/*     variable.                                                            */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD SupportsDMLRowCount
	expose sqlca.
	signal on USER SQLError NAME SupportsDMLRowCountError

	if (self~connSupportsDMLRowCount == '') then do
	    self~connSupportsDMLRowCount = SQLVariable("SUPPORTSDMLROWCOUNT")
		if (self~connSupportsDMLRowCount < 0) then do
			sqlca.class = self~class
			sqlca.exception = 'SupportsDMLRowCount failed'
			raise USER SQLError ADDITIONAL (sqlca.~copy)
		end
	end

	return self~connSupportsDMLRowCount

	SupportsDMLRowCountError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD DataTypes                                                       */
/*   - Returns a Stem object containing the data types appropriate for the  */
/*     database.                                                            */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD DataTypes
	expose sqlca.
	signal on USER SQLError NAME DataTypesError

	dt. = self~connDataTypes.
	if (dt.0 == '' & self~connected) then do
	    if (SQLGetInfo(self~connectionName, 'DATATYPES', 'dt.') <> 0) then do
			sqlca.class = self~class
			sqlca.exception = 'DataTypes failed'
			raise USER SQLError ADDITIONAL (sqlca.~copy)
		end
		self~connDataTypes. = dt.
	end

    return self~connDataTypes.

	DataTypesError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD ColumnAttributes                                                */
/*   - Returns a Stem object containing the column attributes appropriate   */ 
/*     for the database.                                                    */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD ColumnAttributes
	expose sqlca.
	signal on USER SQLError NAME ColumnAttributesError

	ca. = self~connColumnAttributes.
	if (ca.0 == '' & self~connected) then do
	    if (SQLGetInfo(self~connectionName, 'DESCRIBECOLUMNS', 'ca.') <> 0) then do
			sqlca.class = self~class
			sqlca.exception = 'ColumnAttributes failed'
			raise USER SQLError ADDITIONAL (sqlca.~copy)
		end
		self~connColumnAttributes. = ca.
	end

    return  self~connColumnAttributes.

	ColumnAttributesError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD SupportsTransactions                                            */
/*   - Returns                                                              */
/*      0 = The database does not support transactions.                     */
/*      1 = The database supports transactions.                             */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD SupportsTransactions
	expose sqlca.
	signal on USER SQLError NAME SupportsTransactionsError

	if (self~connSupportsTransactions == '' & self~connected) then do
    	self~connSupportsTransactions = SQLGetInfo(self~connectionName, 'SUPPORTSTRANSACTIONS')
	    if (self~connSupportsTransactions < 0) then do
			sqlca.class = self~class
			sqlca.exception = 'SupportsTransactions failed'
			raise USER SQLError ADDITIONAL (sqlca.~copy)
		end
	end

	return self~connSupportsTransactions

	SupportsTransactionsError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD SupportsGetColumnData                                           */
/*   - Returns                                                              */
/*      0 = The database does not support the SQLResultTable                */
/*          GetLongColumnData & WriteLongColumnToFile methods.              */
/*      1 = The database does support the SQLResultTable                    */
/*          GetLongColumnData & WriteLongColumnToFile methods.              */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD SupportsGetColumnData
	expose sqlca.
	signal on USER SQLError NAME SupportsGetColumnDataError

	if (self~connSupportsGetColumnData == '' & self~connected) then do
	    self~connSupportsGetColumnData = SQLGetInfo(self~connectionName, 'SUPPORTSSQLGETDATA')
		if (self~connSupportsGetColumnData < 0) then do
			sqlca.class = self~class
			sqlca.exception = 'SupportsFetchColumnData failed'
			raise USER SQLError ADDITIONAL (sqlca.~copy)
		end
	end

	return self~connSupportsGetColumnData

	SupportsGetColumnDataError: raise propagate

/*--------------------------------------------------------------------------*/
/* ::METHOD DBMSName                                                        */
/*   - Returns the name of the database to which the SQLConnection object   */
/*     is connected.                                                        */
/*   - No Arguments.                                                        */
/*--------------------------------------------------------------------------*/
::METHOD DBMSName
	expose sqlca.
	signal on USER SQLError NAME DBMSNameError

	if (self~connDBMSName == '' & self~connected) then do
	    self~connDBMSName = SQLGetInfo(self~connectionName, 'DBMSNAME')
	    if (self~connDBMSName < 0) then do
			sqlca.class = self~class
			sqlca.exception = 'DBMSName failed'
			raise USER SQLError ADDITIONAL (sqlca.~copy)
		end
	end

	return self~connDBMSName 

	DBMSNameError: raise propagate

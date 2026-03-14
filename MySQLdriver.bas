B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=9.85
@EndOfDesignText@
#Event: Connected (Success As Boolean, Message As String)
#Event: QueryResult (Success As Boolean)

Sub Class_Globals
	Private host As String
	Private port As Int
	Private client As Socket
	Private aStream As AsyncStreams
	Private xui As XUI

	Private mCallBack As Object
	Private mEventName As String

	Private bc As ByteConverter
	Private user, pass As String
	Private pBuffer As B4XBytesBuilder
	Private pLenght As Int
	Private PacketID As Byte
	Private NameType As Map

	Private HandS As Boolean
	Private scramble(20) As Byte
	Private RespAuth As Boolean
	Private LastQuery As String 'ignore
	
	Type result (Name As String, Tpe As Int, row As List)
	'Private ListRS As List
	Private ListField As List
	Private ListRecords As List
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(CallBack As Object, EventName As String)
	mCallBack=CallBack
	mEventName=EventName & "_"
	port=3306
	HandS=False
	RespAuth = False
	
	'ListRS.Initialize
	ListField.Initialize
	ListRecords.Initialize
	
	NameType=CreateMap( 0 : "DECIMAL", 1 : "TINYINT", 2 : "SMALLINT", 3 : "INT", _
        4 : "FLOAT", 5 : "DOUBLE", 6 : "NULL", 7 : "TIMESTAMP", 8 : "BIGINT", _
        9 : "MEDIUMINT", 10 : "DATE", 11 : "TIME", 12 : "DATETIME", 13 : "YEAR", _
        14 : "NEWDATE", 15 : "VARCHAR", 16 : "BIT", 245 : "JSON", 246 : "NEWDECIMAL", _
        247 : "ENUM", 248 : "SET", 249 : "TINY_BLOB", 250 : "MEDIUM_BLOB", _
        251 : "LONG_BLOB", 252 : "BLOB", 253 : "VAR_STRING", 254 : "STRING", 255 : "GEOMETRY")
End Sub

Public Sub Connect(Address As String,username As String, password As String)
	host=Address
	user=username
	pass=password
	
	HandS=False
	RespAuth = False
	
	If Not(client.IsInitialized) Then client.Initialize("client")
	If client.Connected Then
		client.Close
		Sleep(100)
		client.Initialize("client")
	End If
	client.Connect(host,port,3000)
	pBuffer.Initialize
	
	PacketID=1
End Sub

Private Sub client_Connected (Successful As Boolean)
	If Successful Then
		aStream.Initialize( client.InputStream, client.OutputStream, "aStream")
	Else
		If xui.SubExists(mCallBack,mEventName & "Connected",2) Then CallSub3(mCallBack,mEventName & "Connected",False,"donìt response")
	End If
End Sub

Public Sub colSize As Int
	Return ListField.Size
End Sub

Public Sub rowSize As Int
	Return ListRecords.Size
End Sub

Public Sub GetString(field As String) As String
	Dim column As Int = ListField.IndexOf(field)
	Dim Record As List = ListRecords.Get(0)
	Dim B() As Byte= Record.Get(column)
	Try
		Dim S As String = BytesToString(b,0,B.Length,"UTF-8")
	Catch
		Dim S As String = ""
	End Try
	Return S
End Sub

Public Sub GetInt(field As String)  As Int
	Dim column As Int = ListField.IndexOf(field)
	Dim Record As List = ListRecords.Get(0)
	Dim B() As Byte= Record.Get(column)
	Try
		Dim I As Int = BytesToString(b,0,B.Length,"UTF-8")
	Catch
		Dim I As Int = 0
	End Try
	Return I
End Sub

Public Sub GetFloat(field As String)  As Float
	Dim column As Int = ListField.IndexOf(field)
	Dim Record As List = ListRecords.Get(0)
	Dim B() As Byte= Record.Get(column)
	Try
		Dim F As Float = BytesToString(b,0,B.Length,"UTF-8")
	Catch
		Dim F As Float = 0
	End Try
	Return F
End Sub

Public Sub GetDouble(field As String)  As Double
	Dim column As Int = ListField.IndexOf(field)
	Dim Record As List = ListRecords.Get(0)
	Dim B() As Byte= Record.Get(column)
	Try
		Dim D As Double = BytesToString(b,0,B.Length,"UTF-8")
	Catch
		Dim D As Double = 0
	End Try
	Return D
End Sub

Public Sub GetBlob(field As String)  As Byte()
	Dim column As Int = ListField.IndexOf(field)
	Dim Record As List = ListRecords.Get(0)
	Dim B() As Byte= Record.Get(column)
	Return b
End Sub

Public Sub GetString2(column As Int) As String
	Dim Record As List = ListRecords.Get(0)
	Dim B() As Byte= Record.Get(column)
	Try
		Dim S As String = BytesToString(b,0,B.Length,"UTF-8")
	Catch
		Dim S As String = ""
	End Try
	Return S
End Sub

Public Sub GetInt2(column As Int) As Int
	Dim Record As List = ListRecords.Get(0)
	Dim B() As Byte= Record.Get(column)
	Try
		Dim I As Int = BytesToString(b,0,B.Length,"UTF-8")
	Catch
		Dim I As Int = 0
	End Try
	Return I
End Sub

Public Sub GetFloat2(column As Int) As Float
	Dim Record As List = ListRecords.Get(0)
	Dim B() As Byte= Record.Get(column)
	Try
		Dim F As Float = BytesToString(b,0,B.Length,"UTF-8")
	Catch
		Dim F As Float = 0
	End Try
	Return F
End Sub

Public Sub GetDouble2(column As Int) As Double
	Dim Record As List = ListRecords.Get(0)
	Dim B() As Byte= Record.Get(column)
	Try
		Dim D As Double = BytesToString(b,0,B.Length,"UTF-8")
	Catch
		Dim D As Double = 0
	End Try
	Return D
End Sub

Public Sub GetBlob2(column As Int) As Byte()
	Dim Record As List = ListRecords.Get(0)
	Dim B() As Byte= Record.Get(column)
	Return b
End Sub

Public Sub ResultsetNext As Boolean
	ListRecords.RemoveAt(0)
	Return (ListRecords.Size>0)
End Sub

Public Sub GetFieldType(column As Int) As Int
	Return ListField.Get(column).As(result).Tpe
End Sub

Public Sub GetFieldTypeName(column As Int) As String
	Return NameType.GetDefault(ListField.Get(column).As(result).Tpe,"unknown").As(String)
End Sub

Public Sub GetFieldName(column As Int) As String
	Return ListField.Get(column).As(result).name
End Sub

#Region old method
'
'Public Sub GetString3(column As Int, row As Int) As String	
'	Dim Record As List = ListRecords.Get(row)
'	Dim B() As Byte= Record.Get(column)
'	Dim S As String = BytesToString(b,0,B.Length,"UTF-8")
'	Return S
'End Sub
'
'Public Sub GetInt3(column As Int, row As Int) As Int
'	Dim Record As List = ListRecords.Get(row)
'	Dim B() As Byte= Record.Get(column)
'	Dim I As Int = BytesToString(b,0,B.Length,"UTF-8")
'	Return I
'End Sub
'
'Public Sub GetFloat3(column As Int, row As Int) As Float
'	Dim Record As List = ListRecords.Get(row)
'	Dim B() As Byte= Record.Get(column)
'	Dim F As Float = BytesToString(b,0,B.Length,"UTF-8")
'	Return F
'End Sub
'
'Public Sub GetDouble3(column As Int, row As Int) As Double
'	Dim Record As List = ListRecords.Get(row)
'	Dim B() As Byte= Record.Get(column)
'	Dim D As Double = BytesToString(b,0,B.Length,"UTF-8")
'	Return D
'End Sub
'
'Public Sub GetBlob3(column As Int, row As Int) As Byte()
'	Dim Record As List = ListRecords.Get(row)
'	Dim B() As Byte= Record.Get(column)
'	Return b
'End Sub

#End region

#region Stream

Private Sub aStream_NewData (Buffer() As Byte)
'	Log("rec: " & Buffer.Length)
	If Not(HandS) Then
		parseHandshake(Buffer)
	else if Not(RespAuth) Then
		AddToBuffer(Buffer)
		
		If pLenght=pBuffer.Length Then
			pLenght=0
			Dim bf() As Byte = pBuffer.ToArray
			If (bf(0) = 0x00)  Then
				Log("Authentication successful!")
				RespAuth=True
				If xui.SubExists(mCallBack,mEventName & "Connected",2) Then CallSub3(mCallBack,mEventName & "Connected",True,"Connected")
			else if (Bit.And( bf(0),0xFF) = 0xff)  Then
				'Log("Errore durante l'autenticazione.")
				Log(BytesToString(bf,3,bf.Length-3,"UTF-8"))
				If xui.SubExists(mCallBack,mEventName & "Connected",2) Then CallSub3(mCallBack,mEventName & "Connected",False,BytesToString(bf,3,bf.Length-3,"UTF-8"))
			Else
				Log("Unrecognized response.")
				If xui.SubExists(mCallBack,mEventName & "Connected",2) Then CallSub3(mCallBack,mEventName & "Connected",False,"Unrecognized response.")
			End If
			pBuffer.Clear
		End If
	Else
		' QUERY
		AddToBuffer(Buffer)
		If pLenght<=pBuffer.Length Then
			pLenght=0
		
			ListField.Clear
			ListRecords.Clear
			ListRecords.Add(Null)
			If pBuffer.InternalBuffer(0)=0x00 Then
'				Log("Successo: " & LastQuery)
				pBuffer.Clear
				'Sleep(100)
				If xui.SubExists(mCallBack,mEventName & "QueryResult",1) Then CallSubDelayed2(mCallBack,mEventName & "QueryResult",True)
			Else If Bit.And(pBuffer.InternalBuffer(0),0xff)=0xff Then
				Dim ms() As Byte = pBuffer.SubArray(9)
				Log("Errore: " & BytesToString(ms,0,ms.Length,"UTF-8"))
				pBuffer.Clear
				If xui.SubExists(mCallBack,mEventName & "QueryResult",1) Then CallSub2(mCallBack,mEventName & "QueryResult",False)
			Else
'				Log("Result set: " & pBuffer.Length)
				parseQueryResponse(pBuffer.ToArray)
				'Sleep(100)
				If xui.SubExists(mCallBack,mEventName & "QueryResult",1) Then CallSubDelayed2(mCallBack,mEventName & "QueryResult",True)
			End If
						
		End If
	End If
End Sub

Private Sub aStream_Error
	Log("Error")
End Sub

Private Sub aStream_Terminated
	Log("Terminated")
End Sub

#End Region

#Region Handshake

Private Sub parseHandshake(Buffer() As Byte)
	Log("BUFFER: " & Buffer.Length)
	If Buffer(0)=0x46 Then 
		If xui.SubExists(mCallBack,mEventName & "Connected",2) Then CallSub3(mCallBack,mEventName & "Connected",False,"Address unauthorized")
		Return
	End If
		
	Dim packetLength  As Int = CalcLen(Buffer)
	If (packetLength = Buffer.Length-4) Then
		Dim versionEnd As Int = 0
		For i=4 To Buffer.length-1
			If (Buffer(i) = 0) Then
				versionEnd = i
				Exit
			End If
		Next
		Dim serverVersion As String = BytesToString(Buffer,5,versionEnd-4,"UTF-8")
		Log("Connesso al server MySQL, versione: " & serverVersion)
		
		' Estrarre part1 del salt
		Dim part1(8) As Byte
		bc.ArrayCopy(Buffer,versionEnd + 5,part1,0,8)
		
		' Estrarre part2 del salt
		Dim part2(12) As Byte
		bc.ArrayCopy(Buffer,Buffer.Length - 13,part2,0,12)
		
		' Unire part1 + part2 nello scramble
		bc.ArrayCopy(part1,0,scramble,0,part1.Length)
		bc.ArrayCopy(part2,0,scramble,part1.Length,part2.Length)
				
		HandS=True
		createAuthPacket
	End If
End Sub

Private Sub createAuthPacket
	Dim Buf As B4XBytesBuilder ' Max 256 byte
	Dim filler(23) As Byte
	Private hashedPassword() As Byte = ScramblePassword(pass, scramble)
	
	Buf.Initialize
	' 32 byte
	Buf.Append(Array As Byte(0x03,0xA6,0x85,0x00)) 'client capabilities flags - 0x0085A603
	Buf.Append(Array As Byte(0x00,0x00,0x00,0x40)) 'Max packet size - 0x40000000
'	Buf.Append(Array As Byte(0x00,0x85,0xA6,0x03)) 'client capabilities flags - 0x85A603
'	Buf.Append(Array As Byte(0x40,0x00,0x00,0x00)) 'Max packet size - 0x40000000
		
	Buf.Append(Array As Byte(33)) ' Charset utf-8mb4
	Buf.Append(filler) 'Filler (23 byte)
	' REMAIN 228
	Buf.Append(user.GetBytes("UTF-8")) ' user name
	Buf.Append(Array As Byte(0)) ' null terminated
	' HASH Password
	Dim Bt As Byte = hashedPassword.Length
	Buf.Append(Array As Byte(Bt)) ' password length
	Buf.Append(hashedPassword) ' password
	sendPacket(Buf.ToArray)
	
	pBuffer.Clear
	pLenght=0
End Sub

Sub ScramblePassword(password As String, scramb() As Byte) As Byte()
	' Step 1: SHA1(password)
	If password.Length=0 Then Return Array As Byte()
	Dim stage1() As Byte = SHA1(password.GetBytes("UTF-8"))

	' Step 2: SHA1(SHA1(password))
	Dim stage2() As Byte = SHA1(stage1)

	' Step 3: SHA1(concat(salt, SHA1(SHA1(password))))
	Dim combined(scramb.Length + stage2.Length ) As Byte
	For i = 0 To scramb.Length - 1
		combined(i) = scramb(i)
	Next
	For i = 0 To stage2.Length - 1
		combined(scramb.Length + i) = stage2(i)
	Next
	Dim stage3() As Byte = SHA1(combined)

	' XOR between stage1 and stage3
	Dim result(stage1.Length ) As Byte
	For i = 0 To stage1.Length - 1
		result(i) = Bit.Xor(stage1(i), stage3(i))
	Next

	Return result
End Sub

#End Region

#Region Comunication

Public Sub executeQuery(Query As String)
	' Creiamo un pacchetto per inviare la query
	Dim Buf As B4XBytesBuilder ' Max 1024 byte
	Buf.Initialize
	Buf.Append(Array As Byte(0x03)) ' COM_QUERY command
	Buf.Append(Query.GetBytes("UTF-8")) 'La query come stringa
	LastQuery=Query
	
	'Invio il pacchetto con la query
	sendPacket(Buf.ToArray)
End Sub

Private Sub sendPacket(Packet() As Byte)
	Dim lenght As Int = Packet.Length
	Dim Hader(4) As Byte = Array As Byte(Bit.And(lenght,0xff),Bit.And(Bit.ShiftRight(lenght,8),0xff),Bit.And(Bit.ShiftRight(lenght,16),0xff),PacketID)
'	Log("I:" & PacketID)
	aStream.Write(Hader)
	aStream.Write(Packet)
	PacketID=0
End Sub

Private Sub parseQueryResponse(packet() As Byte)
	Dim columnCount As Int = Bit.And(packet(0),0xff) ' Numero di colonne nel result set
	Dim Start As Int = 1
	Dim Stop As Int
	Dim buf As B4XBytesBuilder
	
	Dim sp As Int
		
	buf.Initialize
	buf.Append(packet)
	
'	Log("Column : " & columnCount)
	' (3) packed len (1) packed id
	Stop=buf.IndexOf2(Array As Byte(0xFE,0x00,0x00),Start) + 3
'	Log("Len: " & packet.Length & " -  Fine: " & Stop)
	For i = 0 To columnCount-1
		' Field Descriptor
		Dim rs As result
		rs.Initialize
		rs.row.Initialize
		
		Start=Start+4 ' jump - (3) len (1) ip packet
'		Log("__________________________")
'		Log("Inizio: " & Start )
		' jump: Catalog, Database, Table, O-Table
		sp=Bit.And(packet(Start),0xFF) ' catalog
'		Log(ExtractText(packet,Start+1,sp))
		Start=Start + sp + 1
		sp=Bit.And(packet(Start),0xFF) ' database
'		Log(ExtractText(packet,Start+1,sp))
		Start=Start + sp + 1
		sp=Bit.And(packet(Start),0xFF) ' Table
'		Log(ExtractText(packet,Start+1,sp))
		Start=Start + sp + 1
		sp=Bit.And(packet(Start),0xFF) ' O-Table
		Start=Start + sp + 1
		
		sp=Bit.And(packet(Start),0xFF) ' Name field
		rs.name=ExtractText(packet,Start+1,sp)
'		Log(ExtractText(packet,Start+1,sp))
		Start=Start + sp + 1
		sp=Bit.And(packet(Start),0xFF) ' O-Name field
		Start=Start + sp + 1
		Start=Start + 1 ' (1) 12
		Start=Start + 6 ' jump - (2) charset - (4) field lenght
		rs.Tpe=Bit.And(0xff,packet(Start)) ' (1) Type field
'		Log("type: " & Bit.And(0xff,packet(Start)))
		Start=Start + 1
		' 2 FLAG
		Start=Start + 2
		' (1) decimal places
		' (2) 0x00.0x00
		Start=Start+3
		
		ListField.Add(rs)
	Next
	Start=Stop + 2 ' EOF
	Stop=buf.IndexOf2(Array As Byte(0xFE,0x00,0x00),Start) - 4
	
	Dim nPacked As Int = 0
'	Log("################### Fine: " & Stop)
	Do While Start<Stop
		Dim len As Int= CalcLenPos(packet,Start) 'ignore
		'Log($"Lunghezza Pacchetto dati (${nPacked}): ${len}"$)
		Start=Start+4 ' jump - (3) len (1) ip packet
		'LogColor(BytesToString(buf.ToArray,Start,buf.Length-Start-1,"UTF-8"),xui.Color_Magenta)
		
		Dim SingleRecord As List
		SingleRecord.Initialize
		For i = 0 To columnCount-1
			sp=cLen(packet,Start) ' field len
			Start=Start+addrLen(packet,Start)
			SingleRecord.Add(buf.SubArray2(Start,Start+sp))
			Start=Start + sp
		Next
		ListRecords.add(SingleRecord)
		'Sleep(0)

		nPacked=nPacked+1
	Loop
	
	pBuffer.Clear
End Sub

Private Sub ExtractText(P() As Byte, start As Int, len As String) As String
	Return BytesToString(P,start,len,"UTF-8")
End Sub


#End Region

#Region funtion 

Private Sub AddToBuffer(Buffer() As Byte)
	If pLenght=0 Then
'		Log("R3: "  &  Buffer(3))
		pLenght = CalcLen(Buffer)
		pBuffer.Append2(Buffer,4,Buffer.Length-4)
	Else
		pBuffer.Append2(Buffer,0,Buffer.Length)
	End If
End Sub

Private Sub CalcLen(D() As Byte) As Int
	Dim DataInt(4) As Byte = Array As Byte (0x00,d(2),d(1),d(0))
	Dim L As Int = bc.IntsFromBytes(DataInt)(0)
	
	Return l
End Sub

Private Sub CalcLenPos(D() As Byte,Pos As Int) As Int
	Dim DataInt(4) As Byte = Array As Byte (0x00,d(2+Pos),d(1+Pos),d(0+Pos))
	Dim L As Int = bc.IntsFromBytes(DataInt)(0)
	
	Return l
End Sub

Private Sub cLen(D() As Byte,Pos As Int) As Int
	Dim first As Int = Bit.And(0xff,D(Pos))
	If first<251 Then
		Return first
	else If first= 0xfb Then  ' null
		Return 0
	Else if first= 0xfc Then ' 2 byte
		Return bc.IntsFromBytes(Array As Byte(0x00,0x00,D(Pos+2),D(Pos+1)))(0)
	Else if first= 0xfd Then ' 3 byte
		Return bc.IntsFromBytes(Array As Byte(0x00,D(Pos+3),D(Pos+2),D(Pos+1)))(0)
	Else if first= 0xfe Then ' 8 byte
		Return bc.IntsFromBytes(Array As Byte(D(Pos+4),D(Pos+3),D(Pos+2),D(Pos+1)))(0)
	Else
		Return -1 ' error
	End If
End Sub

Private Sub addrLen(D() As Byte,Pos As Int) As Int
	Dim first As Int = Bit.And(0xff,D(Pos))
	If first<251 Then
		Return 1
	else if first= 0xfb Then ' null
		Return 1
	Else if first= 0xfc Then ' 2 byte
		Return 2
	Else if first= 0xfd Then ' 3 byte
		Return 3
	Else if first= 0xfe Then ' 8 byte
		Return 8
	Else
		Return 0 ' error
	End If
End Sub

Private Sub isEOFPacket(packet() As Byte) As Boolean 'ignore
	Return (Bit.And(packet(0),0xFF) = 0xFE)
End Sub

Private Sub SHA1(D() As Byte) As Byte()
	Dim R() As Byte

	Dim SHA As MessageDigest
	r = SHA.GetMessageDigest(D,"SHA-1") 

	Return r
End Sub

#End Region

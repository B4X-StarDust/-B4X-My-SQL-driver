B4i=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=6.8
@EndOfDesignText@
#Event: Connected (Success As Boolean, Message As String)
#Event: QueryResult (Success As Boolean)

Sub Class_Globals
	Private host As String
	Private port As Int
	Private client As Socket
	Private aStream As AsyncStreams

	Private mCakkBack As Object
	Private mEventName As String

	Private bc As ByteConverter
	Private user, pass As String
	Private pBuffer As B4XBytesBuilder
	Private pLenght As Int
	Private PacketID As Byte

	Private HandS As Boolean
	Private RespAuth As Boolean
	Private LastQuery As String
	
	'Type result (name As String, Tpe As Int, row As List)
	Private ListRS As List
	
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(CallBack As Object, EventName As String)
	mCakkBack=CallBack
	mEventName=EventName & "_"
	port=3306
	HandS=False
	RespAuth = False
	
	ListRS.Initialize
End Sub

Public Sub Connect(Address As String,username As String, password As String)
	host=Address
	user=username
	pass=password
	client.Initialize("client")
	client.Connect(host,port,3000)
	pBuffer.Initialize
	
	PacketID=1
End Sub

Private Sub client_Connected (Successful As Boolean)
	If Successful Then 
		aStream.Initialize( client.InputStream, client.OutputStream, "aStream")
	End If
End Sub

Public Sub sdResultSet As List
	Return ListRS
End Sub

Public Sub colSize As Int
	Return ListRS.Size
End Sub

Public Sub rowSize As Int
	If ListRS.Size=0 Then 
		Return 0
	Else
		Return ListRS.Get(0).As(result).row.Size
	End If
End Sub

Public Sub GetString(column As Int, row As Int) As String
	Dim r As result = ListRS.Get(column)
	Dim B() As Byte= r.row.Get(row)
	Dim S As String = BytesToString(b,0,B.Length,"UTF8")
	Return S
End Sub

Public Sub GetInt(column As Int, row As Int) As Int
	Dim r As result = ListRS.Get(column)
	Dim B() As Byte= r.row.Get(row)
	Dim I As Int = BytesToString(b,0,B.Length,"UTF8")
	Return I
End Sub

Public Sub GetFloat(column As Int, row As Int) As Float
	Dim r As result = ListRS.Get(column)
	Dim B() As Byte= r.row.Get(row)
	Dim F As Float = BytesToString(b,0,B.Length,"UTF8")
	Return F
End Sub

Public Sub GetDouble(column As Int, row As Int) As Double
	Dim r As result = ListRS.Get(column)
	Dim B() As Byte= r.row.Get(row)
	Dim D As Double = BytesToString(b,0,B.Length,"UTF8")
	Return D
End Sub

Public Sub GetBlob(column As Int, row As Int) As Byte()
	Dim r As result = ListRS.Get(column)
	Return r.row.Get(row)
End Sub

Public Sub GetFieldType(column As Int) As Int
	Return ListRS.Get(column).As(result).Tpe
End Sub

Public Sub GetFieldName(column As Int) As String
	Return ListRS.Get(column).As(result).name
End Sub

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
				If exist("Connected",2) Then CallSub3(mCakkBack,mEventName & "Connected",True,"Connected")
			else if (bf(0) = 0xff)  Then
				'Log("Errore durante l'autenticazione.")
				Log(BytesToString(bf,3,bf.Length-3,"UTF8"))
				If exist("Connected",2) Then CallSub3(mCakkBack,mEventName & "Connected",False,BytesToString(bf,3,bf.Length-3,"UTF8"))
			Else
				Log("Unrecognized response.")
				If exist("Connected",2) Then CallSub3(mCakkBack,mEventName & "Connected",False,"Unrecognized response.")
			End If
			pBuffer.Clear
		End If
	Else
		' QUERY
		AddToBuffer(Buffer)
		If pLenght<=pBuffer.Length Then
			pLenght=0
		
			ListRS.Clear
			If pBuffer.InternalBuffer(0)=0x00 Then
'				Log("Successo: " & LastQuery)
				pBuffer.Clear
				If exist("QueryResult",1) Then CallSub2(mCakkBack,mEventName & "QueryResult",True)
			Else If Bit.And(pBuffer.InternalBuffer(0),0xff)=0xff Then
				Dim ms() As Byte = pBuffer.SubArray(9)
				Log("Errore: " & BytesToString(ms,0,ms.Length,"UTF8"))
				pBuffer.Clear
				If exist("QueryResult",1) Then CallSub2(mCakkBack,mEventName & "QueryResult",False)
			Else
'				Log("Result set: " & pBuffer.Length)
				parseQueryResponse(pBuffer.ToArray)
				If exist("QueryResult",1) Then CallSub2(mCakkBack,mEventName & "QueryResult",True)
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
	Dim packetLength  As Int = CalcLen(Buffer)
	If (packetLength = Buffer.Length-4) Then
		Dim versionEnd As Int = 0
		For i=4 To Buffer.length-1
			If (Buffer(i) = 0) Then
				versionEnd = i
				Exit
			End If
		Next
		Dim serverVersion As String = BytesToString(Buffer,5,versionEnd-4,"UTF8")
		Log("Connesso al server MySQL, versione: " & serverVersion)
		HandS=True
		createAuthPacket
	End If
End Sub

Private Sub createAuthPacket
	Dim Buf As B4XBytesBuilder ' Max 256 byte
	Dim filler(23) As Byte
	
	Buf.Initialize
	' 32 byte
	Buf.Append(Array As Byte(0x03,0xA6,0x85,0x00)) 'client capabilities flags - 0x0085A603
	Buf.Append(Array As Byte(0x00,0x00,0x00,0x40)) 'Max packet size - 0x40000000
'	Buf.Append(Array As Byte(0x00,0x85,0xA6,0x03)) 'client capabilities flags - 0x85A603
'	Buf.Append(Array As Byte(0x40,0x00,0x00,0x00)) 'Max packet size - 0x40000000
		
	Buf.Append(Array As Byte(33)) ' Charset utf8mb4
	Buf.Append(filler) 'Filler (23 byte)
	' REMAIN 228
	Buf.Append(user.GetBytes("UTF8")) ' user name
	Buf.Append(Array As Byte(0)) ' null terminated
	' HASH Password
	Buf.Append(Array As Byte(0)) ' password length
	Buf.Append(pass.GetBytes("UTF8")) ' password
	sendPacket(Buf.ToArray)
	
	pBuffer.Clear
	pLenght=0
End Sub

#End Region

#Region Comunication

Private Sub sendPacket(Packet() As Byte)
	Dim lenght As Int = Packet.Length
	Dim Hader(4) As Byte = Array As Byte(Bit.And(lenght,0xff),Bit.And(Bit.ShiftRight(lenght,8),0xff),Bit.And(Bit.ShiftRight(lenght,16),0xff),PacketID)
'	Log("I:" & PacketID)
	aStream.Write(Hader)
	aStream.Write(Packet)
	PacketID=0
End Sub

Public Sub executeQuery(Query As String)
	' Creiamo un pacchetto per inviare la query
	Dim Buf As B4XBytesBuilder ' Max 1024 byte
	Buf.Initialize
	Buf.Append(Array As Byte(0x03)) ' COM_QUERY command
	Buf.Append(Query.GetBytes("UTF8")) 'La query come stringa
	LastQuery=Query
	
	'Invio il pacchetto con la query
	sendPacket(Buf.ToArray)
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
		
		ListRS.Add(rs)
	Next
	Start=Stop + 2 ' EOF
	Stop=buf.IndexOf2(Array As Byte(0xFE,0x00,0x00),Start) - 4
	
	Dim nPacked As Int = 0
'	Log("################### Fine: " & Stop)
		Do While Start<Stop
		Dim len As Int= CalcLenPos(packet,Start) 'ignore
'		Log($"Lunghezza Pacchetto dati (${nPacked}): ${len}"$)
		Start=Start+4 ' jump - (3) len (1) ip packet
		
		For i = 0 To columnCount-1
			sp=cLen(packet,Start) ' field len
			Start=Start+addrLen(packet,Start)
'			If ListRS.Get(i).As(result).Tpe<249 Or ListRS.Get(i).As(result).Tpe>251 Then Log(ExtractText(packet,Start,sp))
			ListRS.Get(i).As(result).row.Add(buf.SubArray2(Start,Start+sp))
			Start=Start + sp 
		Next
'		Log("__________________________")
		nPacked=nPacked+1
	Loop
	
	pBuffer.Clear
End Sub

Private Sub ExtractText(P() As Byte, start As Int, len As String) As String
	Return BytesToString(P,start,len,"UTF8")
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

Private Sub exist(event As String,noa As Int) As Boolean 'ignore
	#IF B4I
		Return SubExists(mCakkBack,mEventName & event,noa)
	#Else
	Return SubExists(mCakkBack,mEventName & event)
	#End If
End Sub

#End Region

#Region Old method

'Private Sub ProcessingResultSet2(packet() As Byte)
'	Dim columnCount As Int = Bit.And(packet(0),0xff) ' Numero di colonne nel result set
'	Dim Start As Int = 1
'	Dim Stop As Int
'	Dim buf As B4XBytesBuilder
'   Private ConstSpace As Int = 4
'	
''	Log("Colonne : " & columnCount)
'	' column name
'	buf.Initialize
'	buf.Append(packet)
'	For i = 0 To columnCount-1
'		Stop=buf.IndexOf2(Array As Byte(0xFE),Start) ' EOF packet
'		If Stop=-1 Then Stop=buf.Length
'		Dim b() As Byte = buf.SubArray2(Start,Stop)
'		Start=Stop+1
''		Log(parseColumnDefinition(b))
'		ListRS.Add(Createresult(parseColumnDefinition(b),""))
'		Log(BytesToString(b,0,b.Length,"UTF8"))
'	Next
'	
'	' data row
'	buf.Remove(0,Min(Stop+1,buf.Length))
''	Log("Buffer: " & buf.Length)
'	Dim Len As Int = CalcLenRev(buf.InternalBuffer)
'
'	Do While Len<>0xFE And buf.Length<>0
'		Dim v() As Byte = buf.SubArray2(0,Len+ConstSpace)
'		parseRowData(buf.SubArray2(0,Len+ConstSpace),columnCount,Len)
'		Log(BytesToString(v,0,v.Length,"UTF8"))
'		buf.Remove(0,Min(Len+ConstSpace,buf.Length))
''		Log("Buffer:" & buf.Length)
'		Len=CalcLenRev(buf.InternalBuffer)
'	Loop
'	
'	If exist("QueryResult",1) Then CallSub2(mCakkBack,mEventName & "QueryResult",True)
'	
'	runQuery=False
'End Sub

'Private Sub parseColumnDefinition(packet() As Byte) As String
'	'Dim Ls As List
'	Dim s As String = ""
'	Dim nameStart As Int = 0
'	Dim nameEnd As Int = 0
'	
'	'   Parsing base del pacchetto per ottenere il nome della colonna
'	'Ls.Initialize
'	Do While nameStart<packet.Length
'		nameStart = findNthZero(packet, nameStart, 4) + 1 ' Nome della colonna dopo alcuni campi
'		If nameStart>0 Then
'			nameEnd = findNthZero(packet, nameStart, 1)
'			'Ls.Add(BytesToString(packet,nameStart,nameEnd-nameStart,"UTF8"))
'			s=S & BytesToString(packet,nameStart,nameEnd-nameStart,"UTF8") & " "
'			nameStart=nameEnd+1
'		Else
'			nameStart=packet.Length
'		End If
'	Loop
'	' 8,11,12
'	
'	Return s.Trim
'End Sub

'Private Sub parseRowData(packet() As Byte, columnCount As Int, Len As Int)
'	Dim pos As Int = 0
'   Private ConstSpace As Int = 4
'	If Len>4 And Bit.And(packet(4),0xff)<>0xFE Then
'		For i = 0 To columnCount-1
'			pos=pos+ConstSpace
'			' string
'			pos=pos+1
'			Len=Len-1
'			Dim columnValue As String = BytesToString(packet,pos,Len,"UTF8")
'			pos=pos+Len+1
''			Log("Column name: " & columnValue)
'			
'			Dim Column As result = ListRS.Get(i)
'			Column.col.Add(columnValue)
'		Next
'	End If
'End Sub

'Private Sub CalcLenRev(D() As Byte) As Int
'	Dim DataInt(4) As Byte = Array As Byte (0x00,0x00,d(1),d(0))
'	Dim L As Int = bc.IntsFromBytes(DataInt)(0)
'	
'	Return l
'End Sub

'Private Sub findNthZero(packet() As Byte, start As Int, n As Int) As Int
'	Dim zeroCount As Int = 0
'	For i = start To packet.Length-1
'		If packet(i)=0 Then zeroCount=zeroCount+1
'		If zeroCount=n Then Return i
'	Next
'
'	Return -1
'End Sub
'
'Private Sub FindDblZero(B As B4XBytesBuilder,Start As Int, N As Int) As Int
'	Dim DzeroCount As Int = 0
'	
'	Do While DzeroCount<n And Start>-1
'		Start=B.IndexOf2(Array As Byte(0x00,0x00),Start+1)
'		If Start>-1 Then DzeroCount=DzeroCount+1
'	Loop
'	
'	Return Start
'End Sub

'private Sub Createresult (name As String, Tpe As Int) As result
'	Dim t1 As result
'	t1.Initialize
'	t1.name = name
'	t1.Tpe = Tpe
'	t1.row.Initialize
'	Return t1
'End Sub

#End Region
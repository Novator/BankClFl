  if ReadedCount>0 then
  begin
    J := ReadedCount;
    ReadedCount := 0;
    ReceiveBufLen := ReceiveBufLen-J;
    if ReceiveBufLen>0 then
    begin
      try
        Buf := AllocMem(ReceiveBufLen);
        Move(ReceiveBuf[J], Buf^, ReceiveBufLen);
        FreeMem(ReceiveBuf);
        ReceiveBuf := Buf;
      except
        Step := csError;
        AddProto(plWarning, SockTitle, 'Ошибка перемещения буфера чтения');
      end;
    end
    else begin
      try
        ReceiveBufLen := 0;
        FreeMem(ReceiveBuf);
        ReceiveBuf := nil;
      except
        Step := csError;
        AddProto(plWarning, SockTitle, 'Ошибка освобождения буфера чтения');
      end;
    end;
  end;

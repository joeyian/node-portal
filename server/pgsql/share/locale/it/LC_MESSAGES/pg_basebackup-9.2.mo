��    �        �         �
     �
     �
  !   �
  
     -   '     U  3   g  K   �  <   �  >   $  3   c  <   �  ?   �  M     k   b  J   �  Y     B   s  *   �  8   �  5     r   P  1   �  3   �  K   )  -   u  4   �  8   �  D     Z   V  P   �  4     @   7  1   x     �  (   �  '   �  &     (   B  -   k  "   �      �  $   �  ,     +   /  .   [  (   �  #   �  5   �  9     7   G  =     "   �  &   �  #     /   +  >   [  Y   �  &   �  &     1   B  0   t     �     �  3   �  2         J  '   k  .   �  #   �  A   �  2   (  &   [  /   �  +   �  4   �  /     !   C  1   e  )   �  (   �  2   �  0     %   N  +   t     �  3   �     �  ,     ,   1  9   ^  A   �  #   �  9   �     8  !   V  &   x  A   �  ,   �  !     (   0  "   Y  9   |  /   �  ,   �       (   &  D   O  8   �  6   �        %      2   C   #   v   R   �   ,   �   I   !  4   d!  >   �!  4   �!  %   "  (   3"  :   \"  1   �"  
   �"  &   �"     �"  �  #     �$     �$  "   %  
   0%  =   ;%     y%  5   �%  T   �%  E   &  B   ]&  =   �&  L   �&  D   +'  q   p'  n   �'  P   Q(  k   �(  I   )  8   X)  D   �)  =   �)  �   *  :   �*  6   �*  l   +  /   �+  >   �+  B   �+  C   <,  Y   �,  O   �,  E   *-  U   p-  >   �-  0   .  4   6.  2   k.  0   �.  ,   �.  1   �.  '   ./  "   V/  &   y/  5   �/  3   �/  2   
0  /   =0  (   m0  C   �0  <   �0  K   1  S   c1  $   �1  >   �1  A   2  N   ]2  `   �2  b   3  (   p3  .   �3  @   �3  R   	4  5   \4  6   �4  L   �4  K   5  %   b5  *   �5  /   �5  7   �5  N   6  9   j6  /   �6  1   �6  <   7  ?   C7  8   �7  C   �7  \    8  /   ]8  -   �8  7   �8  2   �8  (   &9  -   O9     }9  6   �9      �9  -   �9  /   :  S   E:  P   �:  ,   �:  H   ;  $   `;  )   �;  F   �;  M   �;  <   D<  &   �<  0   �<  2   �<  M   =  6   Z=  <   �=     �=  6   �=  S   >  A   o>  G   �>     �>  /   ?  8   C?  4   |?  a   �?  :   @  Q   N@  >   �@  P   �@  8   0A  (   iA  3   �A  D   �A  C   B  
   OB  -   ZB  
   �B     F             '              	      M   S       I      6   T               {       B   >       L   .   K   $   W   @   d   :   l   k               H          A   =      t   1   +   "      m       4       #   
          g   %      c           Q       _   ~   ^       <      a   i   !      G   )                 e      n      8   y   u      2   s   X   C   �   ,   *   \   q              j       p       x       }      [   -   9          w                      7   5   O           r   ?       &             Y   z   v   |      /   0       E      b             3   R      `   f   J       V   P   D              ;   U           h   (           N       Z   o   ]    
Connection options:
 
General options:
 
Options controlling the output:
 
Options:
 
Report bugs to <pgsql-bugs@postgresql.org>.
   %s [OPTION]...
   -?, --help             show this help, then exit
   -D, --directory=DIR    receive transaction log files into this directory
   -D, --pgdata=DIRECTORY receive base backup into directory
   -F, --format=p|t       output format (plain (default), tar)
   -P, --progress         show progress information
   -U, --username=NAME    connect as specified database user
   -V, --version          output version information, then exit
   -W, --password         force password prompt (should happen automatically)
   -X, --xlog-method=fetch|stream
                         include required WAL files with specified method
   -Z, --compress=0-9     compress tar output with given compression level
   -c, --checkpoint=fast|spread
                         set fast or spread checkpointing
   -h, --host=HOSTNAME    database server host or socket directory
   -l, --label=LABEL      set backup label
   -n, --no-loop          do not loop on connection lost
   -p, --port=PORT        database server port number
   -s, --status-interval=INTERVAL
                         time between status packets sent to server (in seconds)
   -v, --verbose          output verbose messages
   -w, --no-password      never prompt for password
   -x, --xlog             include required WAL files in backup (fetch mode)
   -z, --gzip             compress tar output
 %s receives PostgreSQL streaming transaction logs.

 %s takes a base backup of a running PostgreSQL server.

 %s/%s kB (%d%%), %d/%d tablespace %s/%s kB (%d%%), %d/%d tablespaces %s/%s kB (%d%%), %d/%d tablespace (%-30.30s) %s/%s kB (%d%%), %d/%d tablespaces (%-30.30s) %s/%s kB (100%%), %d/%d tablespace %35s %s/%s kB (100%%), %d/%d tablespaces %35s %s: COPY stream ended before last file was finished
 %s: can only write single tablespace to stdout, database has %d
 %s: cannot specify both --xlog and --xlog-method
 %s: child %d died, expected %d
 %s: child process did not exit normally
 %s: child process exited with error %d
 %s: child thread exited with error %u
 %s: could not access directory "%s": %s
 %s: could not close compressed file "%s": %s
 %s: could not close file "%s": %s
 %s: could not connect to server
 %s: could not connect to server: %s
 %s: could not create background process: %s
 %s: could not create background thread: %s
 %s: could not create compressed file "%s": %s
 %s: could not create directory "%s": %s
 %s: could not create file "%s": %s
 %s: could not create pipe for background process: %s
 %s: could not create symbolic link from "%s" to "%s": %s
 %s: could not determine seek position in file "%s": %s
 %s: could not determine server setting for integer_datetimes
 %s: could not fsync file "%s": %s
 %s: could not get COPY data stream: %s %s: could not get backup header: %s %s: could not get child thread exit status: %s
 %s: could not get transaction log end position from server: %s %s: could not identify system: got %d rows and %d fields, expected %d rows and %d fields
 %s: could not initiate base backup: %s %s: could not open directory "%s": %s
 %s: could not open transaction log file "%s": %s
 %s: could not pad transaction log file "%s": %s
 %s: could not parse file mode
 %s: could not parse file size
 %s: could not parse transaction log file name "%s"
 %s: could not parse transaction log location "%s"
 %s: could not read COPY data: %s %s: could not read from ready pipe: %s
 %s: could not receive data from WAL stream: %s %s: could not rename file "%s": %s
 %s: could not seek to beginning of transaction log file "%s": %s
 %s: could not send command to background pipe: %s
 %s: could not send feedback packet: %s %s: could not send replication command "%s": %s %s: could not set compression level %d: %s
 %s: could not set permissions on directory "%s": %s
 %s: could not set permissions on file "%s": %s
 %s: could not stat file "%s": %s
 %s: could not stat transaction log file "%s": %s
 %s: could not wait for child process: %s
 %s: could not wait for child thread: %s
 %s: could not write %u bytes to WAL file "%s": %s
 %s: could not write to compressed file "%s": %s
 %s: could not write to file "%s": %s
 %s: directory "%s" exists but is not empty
 %s: disconnected.
 %s: disconnected. Waiting %d seconds to try again.
 %s: final receive failed: %s %s: finished segment at %X/%X (timeline %u)
 %s: got WAL data offset %08x, expected %08x
 %s: integer_datetimes compile flag does not match server
 %s: invalid checkpoint argument "%s", must be "fast" or "spread"
 %s: invalid compression level "%s"
 %s: invalid output format "%s", must be "plain" or "tar"
 %s: invalid port number "%s"
 %s: invalid status interval "%s"
 %s: invalid tar block header size: %d
 %s: invalid xlog-method option "%s", must be "fetch" or "stream"
 %s: keepalive message has incorrect size %d
 %s: no data returned from server
 %s: no start point returned from server
 %s: no target directory specified
 %s: no transaction log end position returned from server
 %s: not renaming "%s", segment is not complete
 %s: only tar mode backups can be compressed
 %s: out of memory
 %s: received interrupt signal, exiting.
 %s: received transaction log record for offset %u with no file open
 %s: replication stream was terminated before stop point
 %s: segment file "%s" has incorrect size %d, skipping
 %s: select() failed: %s
 %s: starting background WAL receiver
 %s: starting log streaming at %X/%X (timeline %u)
 %s: streaming header too small: %d
 %s: system identifier does not match between base backup and streaming connection
 %s: this build does not support compression
 %s: timeline does not match between base backup and streaming connection
 %s: too many command-line arguments (first is "%s")
 %s: transaction log file "%s" has %d bytes, should be 0 or %d
 %s: unexpected termination of replication stream: %s %s: unrecognized link indicator "%c"
 %s: unrecognized streaming header: "%c"
 %s: waiting for background process to finish streaming...
 %s: wal streaming can only be used in plain mode
 Password:  Try "%s --help" for more information.
 Usage:
 Project-Id-Version: pg_basebackup (PostgreSQL) 9.2
Report-Msgid-Bugs-To: pgsql-bugs@postgresql.org
POT-Creation-Date: 2013-01-29 13:46+0000
PO-Revision-Date: 2012-12-03 17:44+0100
Last-Translator: Daniele Varrazzo <daniele.varrazzo@gmail.com>
Language-Team: Gruppo traduzioni ITPUG <traduzioni@itpug.org>
Language: it
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
Plural-Forms: nplurals=2; plural=n != 1;
X-Generator: Poedit 1.5.4
 
Opzioni di connessione:
 
Opzioni generali:
 
Opzioni di controllo del'output:
 
Opzioni:
 
Puoi segnalare eventuali bug a <pgsql-bugs@postgresql.org>.
   %s [OPZIONE]...
   -?, --help             mostra questo aiuto ed esci
   -D, --directory=DIR    ricevi i file di log delle transazioni in questa directory
   -D, --pgdata=DIRECTORY directory in cui ricevere il backup di base
   -F, --format=p|t       formato di output (plain (default), tar)
   -P, --progress         mostra informazioni sull'esecuzione
   -U, --username=NAME    connettiti al database col nome utente specificato
   -V, --version          mostra informazioni sulla versione ed esci
   -W, --password         forza la richiesta della password
                         (dovrebbe essere automatico)
   -X, --xlog-method=fetch|stream
                         includi i file WAL richiesti col metodo specificato
   -Z, --compress=0-9     comprimi l'output tar a questo livello di compressione
   -c, --checkpoint=fast|spread
                         imposta punti di controllo più veloci o più radi
   -h, --host=HOSTNAME    host del server database o directory del socket
   -l, --label=LABEL      imposta l'etichetta del backup
   -n, --no-loop          non ri-eseguire se la connessione è persa
   -p, --port=PORT        numero di porta del server database
   -s, --status-interval=INTERVAL
                         intervallo tra i pacchetti di stato inviati al server
                         (in secondi)
   -v, --verbose          messaggi di output più numerosi
   -w, --no-password      non chiedere mai la password
   -x, --xlog             includi i file WAL necessari nel backup
                         (modalità fetch)
   -z, --gzip             comprimi l'output tar
 %s riceve lo stream del log delle transazioni di PostgreSQL.

 %s crea un backup di base di un server PostgreSQL in esecuzione.

 %s/%s kB (%d%%), %d/%d tablespace %s/%s kB (%d%%), %d/%d tablespace %s/%s kB (%d%%), %d/%d tablespace (%-30.30s) %s/%s kB (%d%%), %d/%d tablespace (%-30.30s) %s/%s kB (100%%), %d/%d tablespace %35s %s/%s kB (100%%), %d/%d tablespace %35s %s: lo stream COPY è terminato prima che l'ultimo file fosse finito
 %s: è possibile scrivere solo un singolo tablespace su stdout, il database ne ha %d
 %s: non è possibile specificare sia --xlog che --xlog-method
 %s: il processo figlio %d interrotto, atteso %d
 %s: il processo figlio non è terminato normalmente
 %s: il processo figlio è terminato con errore %d
 %s: il thread figlio è terminato con errore %u
 %s: accesso alla directory "%s" fallito: %s
 %s: chiusura del file compresso "%s" fallita: %s
 %s: chiusura del file "%s" fallita: %s
 %s: connessione al server fallita
 %s: connessione al server fallita: %s
 %s: creazione del processo in background fallita: %s
 %s: creazione del thread in background fallita: %s
 %s: creazione del file compresso "%s" fallita: %s
 %s: creazione della directory "%s" fallita: %s
 %s: creazione del file "%s" fallita: %s
 %s: creazione della pipe per il processo in background fallita: %s
 %s: creazione del link simbolico da "%s" a "%s" fallita: %s
 %s: determinazione della posizione dove muoversi nel file "%s" fallita: %s
 %s: non è stato possibile determinare l'impostazione integer_datetimes del server
 %s: fsync del file "%s" fallito: %s
 %s: non è stato possibile ottenere lo stream di dati COPY: %s %s: non è stato possibile ottenere l'intestazione del backup: %s %s: non è stato possibile ottenere il codice di uscita del thread figlio: %s
 %s: non è stato possibile ottenere la posizione finale del log delle transazioni dal server: %s %s: identificazione del sistema fallita: ricevute %d righe e %d campi, attese %d righe e %d campi
 %s: avvio del backup di base fallito: %s %s: apertura della directory "%s" fallita: %s
 %s: apertura del file di log delle transazioni "%s" fallita: %s
 %s: correzione della lunghezza del file di log delle transazioni "%s" fallita: %s
 %s: interpretazione della modalità del file fallita
 %s: interpretazione della dimensione del file fallita
 %s: interpretazione del nome del file di log delle transazioni "%s" fallito
 %s: interpretazione della posizione del log delle transazioni "%s" fallita
 %s: lettura dei dati COPY fallita: %s %s: lettura dalla pipe pronta fallita: %s
 %s: ricezione dati dallo stream WAL fallita: %s %s: non è stato possibile rinominare il file "%s": %s
 %s: spostamento all'inizio del file di log delle transazioni "%s" fallito: %s
 %s invio del comando alla pipe di background fallita: %s
 %s: invio del pacchetto di feedback fallito: %s %s: invio del comando di replica "%s" fallito: %s %s: impostazione del livello di compressione %d fallito: %s
 %s: impostazione dei permessi sulla directory "%s" fallita: %s
 %s: impostazione dei permessi sul file "%s" fallita: %s
 %s: non è stato possibile ottenere informazioni sul file "%s": %s
 %s: non è stato possibile ottenere informazioni sul file di log delle transazioni "%s": %s
 %s: errore nell'attesa del processo figlio: %s
 %s: errore nell'attesa del thread figlio: %s
 %s: scrittura di %u byte nel file WAL "%s" fallita: %s
 %s: scrittura nel file compresso "%s" fallita: %s
 %s: scrittura nel file "%s" fallita: %s
 %s: la directory "%s" esiste ma non è vuota
 %s: disconnesso.
 %s: disconnesso. Aspetterò %d secondi per riprovare.
 %s: ricezione finale fallita: %s %s: terminato segmento a %X/%X (timeline %u)
 %s: ricevuto offset dati WAL %08x, atteso %08x
 %s: l'opzione di compilazione integer_datetimes non combacia con quella del server
 %s: argomento di checkpoint "%s" non valido, deve essere "fast" oppure "spread"
 %s: livello di compressione non valido "%s"
 %s: formato di output "%s" non valido, deve essere "plain" oppure "tar"
 %s: numero di porta non valido "%s"
 %s: intervallo di status "%s" non valido
 %s: dimensione del blocco di intestazione del file tar non valida: %d
 %s: opzione xlog-method "%s" non valida, deve essere "fetch" oppure "stream"
 %s: il messaggio di keepalive ha dimensione non corretta %d
 %s: nessun dato restituito dal server
 %s: nessun punto di avvio restituito dal server
 %s: nessuna directory di destinazione specificata
 %s: nessuna posizione finale del log delle transazioni restituita dal server
 %s: non rinominerò "%s", il segmento non è completo
 %s: solo i backup in modalità tar possono essere compressi
 %s: memoria esaurita
 %s: segnale di interruzione ricevuto, sto terminando.
 %s: ricevuti record di log delle transazioni per offset %u senza alcun file aperto
 %s: lo stream di replica è terminato prima del punto di arresto
 %s: il file di segmento "%s" ha la dimensione non corretta %d, saltato
 %s: select() fallita: %s
 %s: avvio del ricevitore dei WAL in background
 %s: avvio dello streaming dei log a %X/%X (timeline %u)
 %s: intestazione dello streaming troppo piccola: %d
 %s: l'identificativo di sistema non combacia tra il backup di base e la connessione in streaming
 %s: questo binario compilato non supporta la compressione
 %s: la timeline non combacia tra il backup di base e la connessione in streaming
 %s: troppi argomenti nella riga di comando (il primo è "%s")
 %s: il file di log delle transazioni "%s" ha %d byte, dovrebbero essere 0 or %d
 %s: terminazione inaspettata dello stream di replica: %s %s: indicatore di link sconosciuto "%c"
 %s: intestazione dello streaming sconosciuta: "%c"
 %s: in attesa che il processo in background finisca lo streaming...
 %s: lo streaming dei WAL può essere usato solo in modalità plain
 Password:  Prova "%s --help" per maggiori informazioni.
 Utilizzo:
 
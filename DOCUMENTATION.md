PREMESSA:

**master**, **rc-branch-v\***, **hc-branch-v\***
- Sono branch che vanno sempre in PARALLELO
- NON devono MAI essere mergiati da nessuna parte!!!

Tutti gli alias finish-* hanno al loro interno la logica che serve per essere "trapiantati"
e mergiati (tramite pull request) sul prossimo branch di destinazione. Questo tipo
di alias va eseguito sul branch in oggetto un numero di volte variabile (a seconda del tipo e
della situazione in corso) e danno le informazioni necessarie per proseguire con lo step successivo.
E' vietato eseguire rebase a meno che non sia espressamente indicato.

Ogni comando di tipo finish-* offre quando si e' arrivati allo step finale la
possibilita' di cancellare il branch ormai inutile per mantenere il repo
in ordine. Da github c'e' sempre la possibilita' di ricreare il branch cancellato qualora
ce ne fosse bisogno.

Assieme alla suite di alias specifici per ogni branch, esiste anche un alias
che serve semplicemente a pushare su di un branch remoto specificato, la HEAD del branch
corrente:

**git release**

    usage:
    git release <target_branch>
    description:
    Il target branch deve esistere gia' in remoto e verra' sovrascritto dal branch
    nel quale viene lanciato il comando


# master (aka trunk)

Branch dal quale vengono creati i docs/chore/test/refactor/feature/bugfix branch
di seguito noti anche come **fb-branch**

Su target process mappiamo i feature con le User Story, mentre i bugfix con i Bug.
La maggior parte dei branch creati da master saranno di questi due tipi ma per completezza
qui un elenco esaustivo di cosa ogni tipo di branch dovrebbe contenere e cosa va a toccare,
se non altro per filtrare le cose che non hanno bisogno di test manuali:

**NO production CODE or BEHAVIOUR change**

    docs: (changes to the documentation, adding docs to a function/component, etc.)
    chore: (updating webpack config, fine tuning uglifying, etc.)
    test: (adding missing tests, refactoring existing tests)

**production CODE WITHOUT BEHAVIOUR change**

    refactor: (split a complex component into many smaller without changing the whole behaviour)

**production CODE and BEHAVIOUR change**

    feature: (NEW feature for the USER, NOT a new feature for a dev SCRIPT)
    bugfix: (bug fix for the USER, NOT a fix to a dev SCRIPT)


Ogni fb-branch quando completato verra' portato su master tramite pull request innescata
dal comando git finish-fb

Git alias coinvolti:

**git create-fb**

    usage:
    git create-fb <docs|chore|test|refactor|feature|bugfix>/<TP_ID|desc>
    description:
    Serve per creare un nuovo fb-branch
    N.B. Il branch verra' creato sempre a partire dall'ultimo commit di origin/master, a prescindere 
    dal branch in cui viene eseguito l'alias

**git finish-fb**

    usage:
    git finish-fb (lanciato all'interno del fb-branch)
    description:
    Serve per creare la pull-request su master del branch in questione.

**git create-rc**

    usage:
    git create-rc
    description:
    Serve per creare un nuovo release candidate branch nel formato: rc-branch-v*
    N.B. E' necessario utilizzare il comando: git release release-qa, per allineare
    l'ambiente di QA con l'appena creato rc-branch

**git list-fb**

    usage:
    git list-fb [preview]
    description:
    - Se chiamato con l'argomento preview, mostra l'elenco dei fb-branch che verrebbero inseriti
    nel nuovo rc-branch qualora creato
    - Se chiamato senza argomenti mostra l'elenco dei fb-branch collegati all'ultimo rc tag

# rc-branch-v\*

Branch che viene creato quando si decide di portare in produzione i nuovi fb-branch mergiati su master.

E' assolutamente vietato effettuare NUOVI sviluppi in questo tipo di branch.
Gli sviluppi **nuovi** vanno fatti sempre su **master**!!!

Questo branch viene rilasciato in ambiente di QA, dove verranno svolti i test di integrazione per validare gli
sviluppi ed eventualmente effettuare bugfix o, qualora fosse strettamente necessario,
inibire alcune funzionalita' per il rilascio corrente.

Da questo branch possono essere creati due tipi di branch:
1) **rc-fix** branch
2) **rc-inhibit** branch

1\) Sono semplicemente branch nei quali vengono effettuati gli sviluppi per risolvere dei bug che si rendono
noti solo quando si rilascia l'**rc-branch** in QA. La necessita' di avere un flusso dedicato per questo tipo di bugfix risiede nel fatto che serve un modo per poter riportare
tali modifiche anche sul branch master. Dal momento che sono vietati i merge da rc-branch a master
sono stati previsti due alias rispettivamente per iniziare e concludere lo sviluppo di un rc-fix.

2\) Sono branch dove vengono "sviluppati" dei workaround temporanei per nascondere/inibire qualcosa nel **rc-branch** corrente
in modo da non rilascirli in produzione. A differenza dei rc-fix branch al punto 1, questi non devono essere riportati su master perche' l'inibizione viene fatta a livello
di rc-branch corrente e si spera che i problemi che hanno impedito la messa in produzione in questo rc-branch
siano risolti al rilascio successivo.

Git alias coinvolti:

Per i branch di tipo rc-fix:

**git create-rc-fix**

    usage:
    git create-rc-fix <fb-branch|TP>
    description:
    E' il comando che permette di creare un nuovo rc-fix branch

**git finish-rc-fix**

    usage:
    git finish-rc-fix
    description:
    Bisognera' eseguire questo comando DUE volte:
    1) Serve per "incorporare" la fix sul rc-branch corrente (verra' creata una pull-request sul rc-branch corrente)
    2) Serve per "incorporare" la fix su master, va eseguito IMMEDIATAMENTE dopo che la pull-request al punto 1
    e' stata approvata e mergiata, inoltre la seconda pull-request va approvata SEMPRE, eventuali change request vanno
    comunicate nella pull-request sul rc-branch.
    N.B.1 Il comando va lanciato all'interno del rc-fix branch
    N.B.2 Dopo che la pull request e' stata mergiata sul rc-branch corrente
    per allineare l'ambiente di QA con le nuove modifiche e' necessario portarsi nel rc-branch corrente

    git checkout $(git rc-branch)

    e successivamente lanciare questo comando

    git release release-qa

Per i branch di tipo rc-inhibit:

**git create-rc-inhibit**

    usage:
    git create-rc-inhibit <fb-branch|TP>
    description:
    E' il comando che permette di creare un nuovo rc-inhibit branch

**git finish-rc-inhibit**

    usage:
    git finish-rc-inhibit
    description:
    Bisognera' eseguire questo comando UNA volta:
    1) Serve per "incorporare" la fix sul rc-branch corrente (verra' creata una pull-request sul rc-branch corrente)
    N.B. Il comando va lanciato all'interno del rc-inhibit branch
    per allineare l'ambiente di QA con le nuove modifiche e' necessario portarsi nel rc-branch corrente

    git checkout $(git rc-branch)

    e successivamente lanciare questo comando

    git release release-qa


Una volta che tutte le nuove feature ed i bugfix portati in QA, sono stati testati e laddove necessario effettuate le opportune fix,
il rc-branch e' pronto per poter essere portato in produzione.
A tal proposito esiste un alias dedicato:

## git release-rc

    usage:
    git release-rc (lanciato all'interno del rc-branch in corso)
    description:
    Inneschera' un rilascio in produzione pushando sul branch dedicato (release-prod) ed inoltre
    creera' un nuovo tag di produzione del tipo prod-v(CURRENT N+1)
    N.B. Dato che Il comando va lanciato all'interno del rc-branch corrente e
    possibile utilizzare il seguente comando per fare il checkout di tale branch

    git checkout $(git rc-branch)



# hc-branch-v\*

Branch che viene automaticamente creato quando si rende necessario effettuare una hotfix.

Esso serve come base di appoggio per i branch di hotfix e ci da la possibilita' di effettuare
piu' di una hotfix in sequenza, effettuando un solo rilascio.

Git alias coinvolti:

**git create-hotfix**

    usage:
    git create-hotfix <TP|desc>
    description:
    La prima volta che viene chiamato crea anche l'hc-branch di "appoggio" che viene "staccato"
    a partire dall'ultimo tag di prod.
    Le volte successive solo l'hotfix branch verra' creato e verra' staccato dal remote
    dell'ultimo hc-branch

**git finish-hotfix**:

    usage:
    git finish-hotfix
    description:
    Bisognera' eseguire questo comando DUE o TRE volte dipendentemente dall'esistenza
    o meno di un rc-branch non ancora rilasciato. La prima esecuzione e' identica in entrambi i casi
    1) Incorporare la hotfix sul hc-branch corrente (pull-request su hc-branch)

    Nel caso, piu' semplice, di non esistenza di un rc-branch in corso
    2a) Incorporare la hotfix su master IMMEDIATAMENTE dopo che la pull-request al punto 1
    e' stata approvata e mergiata.

    Nel caso, piu' complesso, di esistenza di un rc-branch
    2b) Incorporare la hotfix su rc-branch IMMEDIATAMENTE dopo che la pull-request al punto 1
    e' stata approvata e mergiata.
    3) Incorporare la hotfix su master IMMEDIATAMENTE dopo che la pull-request al punto 2a
    e' stata approvata e mergiata.

    N.B.1. Il comando va lanciato all'interno dell'hotfix branch

    N.B.2 Dopo che la pull request e' stata mergiata sul hc-branch corrente
    per allineare l'ambiente di PREPROD con le nuove modifiche e' necessario portarsi nel hc-branch corrente

    git checkout $(git hc-branch)

    e successivamente lanciare questo comando

    git release release-preprod

    N.B.3 (Se nel caso 2b) Dopo che la pull request e' stata mergiata sul rc-branch corrente
    per allineare l'ambiente di QA con le nuove modifiche e' necessario portarsi nel rc-branch corrente

    git checkout $(git rc-branch)

    e successivamente lanciare questo comando

    git release release-qa


## git release-hc

    usage:
    git release-hc (lanciato all'interno dell'ultimo hc-branch)
    description:
    Cosi' come per l'rc-branch anche l'hc-branch ha un comando dedicato per innescare un rilascio
    in produzione sul branch dedicato. Anche in questo caso verra' creato un nuovo tag di produzione.
    N.B. Dato che Il comando va lanciato all'interno del hc-branch corrente e
    possibile utilizzare il seguente comando per fare il checkout di tale branch

    git checkout $(git hc-branch)


































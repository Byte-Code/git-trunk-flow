MAIN RULES:

master, rc-branch-v*, hc-branch-v*
- sono branch che vanno sempre in parallelo
- NON devono MAI essere mergiati da nessuna parte!!!

master:
	Branch dal quale vengono creati i docs/chore/test/refactor/feat/fix branch
	di seguito noti anche come fb-branch

	I feat sono i vecchi feature, mentre i fix sono i vecchi bugfix
	Su target process mappiamo i feat con le User Story, mentre i fix con i Bug
	La maggior parte dei branch creati da master saranno di questi due tipi, ma per completezza
	qui un elenco esaustivo di cosa ogni tipo di branch dovrebbe contenere:

	NO production CODE or BEHAVIOUR change
	docs: (changes to the documentation)
	chore: (Updating webpack config, fine tuning uglifying, etc.)
	test: (adding missing tests, refactoring existing tests;)
	NO production BEHAVIOUR change
	refactor:
	production CODE and BEHAVIOUR change
	feat: (NEW feature for the USER, NOT a new feature for a dev SCRIPT)
	fix: (bug fix for the USER, NOT a fix to a dev SCRIPT)

	Ogni docs/chore/test/style/refactor/feat/fix quando completato verra' portato su master
	tramite pull request.

	Git alias coinvolti:

	git create-fb:
		usage:
		git create-fb <docs|chore|test|style|refactor|feat|fix> <TP_ID|aCamelCasedDescription>
		description:
		Serve per creare un nuovo fb-branch

	git finish-fb:
		usage:
		git finish-fb (lanciato all'interno del fb-branch)
		description:
		Serve per create la pull-request su master del branch in questione.
		N.B. Se il branch corrente non e' allineato con origin/master la pull-request fallira'

	git create-rc:
		usage:
		git create-rc
		description:
		Serve per creare un nuovo release candidate branch nel formato: rc-branch-v*

rc-branch-v*:
	Branch che viene creato quando si decide di portare in produzione le nuove feature sviluppate su master.

	E' assolutamente vietato effettuare NUOVI sviluppi in questo tipo di branch.
	Gli sviluppi nuovi vanno fatti sempre su master!!!

	Questo branch viene rilasciato in ambiente di QA, dove verranno svolti i test di integrazione per validare gli
	sviluppi ed eventualmente effettuare bugfix o qualora fosse strettamente necessario, inibire alcune funzionalita'
	per il rilascio corrente.

	Da questo branch possono essere creati due tipi di branch:
	1) rc-fix branch
	2) rc-inhibit branch

	1) Sono semplicemente branch nei quali vengono effettuati gli sviluppi per risolvere dei bug che si rendono
	noti solo quando si rilascia in QA o che semplicemente non sono stati notati prima in DEV. La necessita'
	di avere un flusso dedicato per questotipo di bugfix e' che e' necessario avere un modo per poter riportare
	tali modifiche anche sul branch master. Dal momento che sono assolutamente vietati i merge da rc-branch a master
	sono stati previsti due alias rispettivamente per iniziare e concludere lo sviluppo di una rc-fix.

	2)

	Gli alias coinvolti:

	git create-rc-fix
	git create-rc-inhibit
	git release-rc:
		usage:
		git release-rc (lanciato all'interno dell'ultimo rc-branch)
		description:
		Inneschera' un rilascio in produzione pushando sul branch dedicato (release-prod) ed inoltre
		creera' un nuovo tag di produzione del tipo prod-v*

LEGENDA:

rc-branch: release candidate branch
hc-branch: hotfix candidate branch

fb: feature feature/bugfix
hb: feature hotfix

pr: pull request



- Le hotfix sono bugfix da fare il prima possibile in produzione perche' pregiudicano GRAVEMENTE il corretto
  funzionamento dell'applicativo

- I due branch "eterni" sono master e prod.
  - master: accoglie le fb (tramite pr), testate sui propri ambienti di sviluppo e potenzialmente rilasciabili in produzione
  - prod: accoglie le hf (tramite pr), testate su preprod e immediatamente rilasciabili in produzione

- Ogni sviluppo prima di essere portato su master (tramite pr) va testato prima sul proprio ambiente di sviluppo (dev-prodotto etc.).
  Fanno eccezione gli sviluppi, relativi a bugfix di fb in testing o inibizioni di fb, fatti dopo aver staccato un rcb.
  In questo ultimo caso la pr va fatta sul rcb e IMMEDIATAMENTE dopo va fatta su master ed accettata automaticamente al netto di conflitti.

- Un rcb nasce sempre e solo da master
- Dopo aver creato un rcb va manualmente settata la regola di protezione sul branch (da github.com)
- Puo' esistere un solo rcb alla volta
- Il rcb va testato su QA, se necessario puo' essere fatto un ulteriore test su PREPROD
- Il rcb deve avere vita breve

- Le hf hanno sempre priorita' rispetto alle bugfix sul rcb
- Le hf vanno sempre testate su preprod



TODO:
- Prevedere un flag per eliminare i branch quando non servono piu'


feature/26771
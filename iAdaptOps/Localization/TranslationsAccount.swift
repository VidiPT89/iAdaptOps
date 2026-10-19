import Foundation

extension Translations {
    static let account: [String: [Lang: String]] = [
        // MARK: Sign-in screen
        "auth.welcomeBack": [
            .pt: "Entra para continuar o teu programa.",
            .en: "Sign in to carry on with your program."
        ],
        "auth.createSubtitle": [
            .pt: "Cria a tua conta. O teu progresso fica guardado e acompanha-te em qualquer iPhone.",
            .en: "Create your account. Your progress is saved and follows you to any iPhone."
        ],
        "auth.signIn": [.pt: "Entrar", .en: "Sign in"],
        "auth.createAccount": [.pt: "Criar conta", .en: "Create account"],
        "auth.name": [.pt: "Nome", .en: "Name"],
        "auth.email": [.pt: "Email", .en: "Email"],
        "auth.password": [.pt: "Palavra-passe", .en: "Password"],
        "auth.showPassword": [.pt: "Mostrar palavra-passe", .en: "Show password"],
        "auth.hidePassword": [.pt: "Esconder palavra-passe", .en: "Hide password"],
        "auth.forgotPassword": [.pt: "Esqueci-me da palavra-passe", .en: "Forgot your password?"],
        "auth.resetSent": [
            .pt: "Enviámos-te um email para definires uma nova palavra-passe.",
            .en: "We sent you an email to set a new password."
        ],
        "auth.or": [.pt: "ou", .en: "or"],
        "auth.continueApple": [.pt: "Continuar com a Apple", .en: "Continue with Apple"],
        "auth.continueGoogle": [.pt: "Continuar com Google", .en: "Continue with Google"],
        "auth.continueMicrosoft": [.pt: "Continuar com Microsoft", .en: "Continue with Microsoft"],
        "auth.privacyNote": [
            .pt: "Guardamos só o necessário para a tua conta e o teu progresso. Sem anúncios, sem rastreio.",
            .en: "We only keep what your account and progress need. No ads, no tracking."
        ],
        "auth.privacyLink": [.pt: "Política de privacidade", .en: "Privacy policy"],
        "auth.unavailable": [
            .pt: "As contas não estão disponíveis nesta versão da app.",
            .en: "Accounts are not available in this build of the app."
        ],
        "auth.continueGuest": [.pt: "Continuar sem conta", .en: "Continue without an account"],
        "auth.syncing": [.pt: "A preparar o teu programa…", .en: "Getting your program ready…"],
        "auth.guest": [.pt: "Sem conta", .en: "No account"],

        // MARK: Providers
        "auth.provider.email": [.pt: "Entrada com email", .en: "Signed in with email"],
        "auth.provider.google": [.pt: "Entrada com Google", .en: "Signed in with Google"],
        "auth.provider.apple": [.pt: "Entrada com Apple", .en: "Signed in with Apple"],
        "auth.provider.microsoft": [.pt: "Entrada com Microsoft", .en: "Signed in with Microsoft"],

        // MARK: Account in Settings
        "settings.account": [.pt: "Conta", .en: "Account"],
        "auth.signOut": [.pt: "Terminar sessão", .en: "Sign out"],
        "auth.signOutTitle": [.pt: "Terminar sessão?", .en: "Sign out?"],
        "auth.signOutBody": [
            .pt: "O teu progresso continua guardado na conta. Volta a entrar quando quiseres.",
            .en: "Your progress stays saved in your account. Sign back in whenever you like."
        ],
        "auth.deleteAccount": [.pt: "Apagar conta", .en: "Delete account"],
        "auth.deleteTitle": [.pt: "Apagar a conta?", .en: "Delete your account?"],
        "auth.deleteBody": [
            .pt: "A conta, o progresso, o histórico e os check-ins são apagados para sempre. Não dá para desfazer.",
            .en: "Your account, progress, history and check-ins are deleted for good. This cannot be undone."
        ],

        "auth.emailUnverified": [.pt: "Email por confirmar.", .en: "Email not confirmed yet."],
        "auth.resend": [.pt: "Reenviar", .en: "Resend"],
        "auth.verificationSent": [
            .pt: "Enviámos-te o link de confirmação. Abre-o e volta à app.",
            .en: "We sent you the confirmation link. Open it and come back to the app."
        ],

        // MARK: Programs
        "variant.personalized": [.pt: "Plano personalizado", .en: "Personalized plan"],
        "variant.personalized.desc": [
            .pt: "Gerado pela app a partir do questionário de saúde de cada pessoa.",
            .en: "Built by the app from each person's health questionnaire."
        ],
        "variant.anaChallenge": [.pt: "Desafio 28 dias da Ana", .en: "Ana's 28-day challenge"],
        "variant.anaChallenge.desc": [
            .pt: "Plano fixo, exatamente como a Ana o definiu: 28 treinos em 7 semanas, com os alongamentos do plano original.",
            .en: "A fixed plan, exactly as Ana defined it: 28 workouts over 7 weeks, with the stretches from the original plan."
        ],

        // MARK: Admin
        "admin.title": [.pt: "Painel de administração", .en: "Admin panel"],
        "admin.accounts": [.pt: "Contas", .en: "Accounts"],
        "admin.noAccounts": [.pt: "Ainda ninguém entrou na app.", .en: "Nobody has signed in yet."],
        "admin.roleAdmin": [.pt: "Admin", .en: "Admin"],
        "admin.lastWorkout": [.pt: "Último treino: %@", .en: "Last workout: %@"],
        "admin.noWorkoutsYet": [.pt: "Ainda sem treinos", .en: "No workouts yet"],
        "admin.startedOn": [.pt: "Começou a %@", .en: "Started on %@"],
        "admin.notStarted": [.pt: "Ainda não começou o programa", .en: "Has not started the program yet"],
        "admin.program": [.pt: "Programa", .en: "Program"],
        "admin.invites": [.pt: "Perfis por ativar", .en: "Pending profiles"],
        "admin.invitesHint": [
            .pt: "Quando alguém entrar pela primeira vez com um destes emails, a conta começa já com o programa escolhido.",
            .en: "When someone first signs in with one of these emails, their account starts on the chosen program."
        ],
        "admin.newInvite": [.pt: "Novo perfil", .en: "New profile"],
        "admin.saveInvite": [.pt: "Guardar perfil", .en: "Save profile"],
        "admin.deleteInviteTitle": [.pt: "Apagar este perfil?", .en: "Delete this profile?"],
        "admin.error.load": [
            .pt: "Não foi possível carregar as contas. Confirma a ligação e o email de admin.",
            .en: "Could not load the accounts. Check the connection and the admin email."
        ],
        "admin.error.save": [.pt: "Não foi possível guardar. Tenta outra vez.", .en: "Could not save. Please try again."],

        // MARK: Errors
        "auth.error.nameMissing": [.pt: "Escreve o teu nome.", .en: "Please enter your name."],
        "auth.error.invalidEmail": [.pt: "Esse email não parece válido.", .en: "That email does not look right."],
        "auth.error.weakPassword": [
            .pt: "A palavra-passe precisa de pelo menos 6 caracteres.",
            .en: "The password needs at least 6 characters."
        ],
        "auth.error.emailInUse": [
            .pt: "Já existe uma conta com este email. Entra em vez de criares outra.",
            .en: "An account with this email already exists. Sign in instead."
        ],
        "auth.error.wrongCredentials": [
            .pt: "Email ou palavra-passe errados.",
            .en: "Wrong email or password."
        ],
        "auth.error.userDisabled": [.pt: "Esta conta foi desativada.", .en: "This account has been disabled."],
        "auth.error.network": [
            .pt: "Sem ligação à internet. Tenta outra vez daqui a pouco.",
            .en: "No internet connection. Try again in a moment."
        ],
        "auth.error.tooManyRequests": [
            .pt: "Demasiadas tentativas. Espera um pouco e tenta outra vez.",
            .en: "Too many attempts. Wait a little and try again."
        ],
        "auth.error.otherProvider": [
            .pt: "Este email já está ligado a outra forma de entrada. Usa essa.",
            .en: "This email is already linked to another sign-in method. Use that one."
        ],
        "auth.error.recentLogin": [
            .pt: "Por segurança, termina sessão e volta a entrar antes de apagar a conta.",
            .en: "For your security, sign out and back in before deleting your account."
        ],
        "auth.error.providerDisabled": [
            .pt: "Esta forma de entrada ainda não está disponível.",
            .en: "This sign-in method is not available yet."
        ],
        "auth.error.notConfigured": [
            .pt: "O registo e a entrada ainda não estão ativos no servidor da app. Tenta mais tarde.",
            .en: "Sign-up and sign-in are not switched on for the app's server yet. Please try again later."
        ],
        "auth.error.generic": [
            .pt: "Algo correu mal. Tenta outra vez.",
            .en: "Something went wrong. Please try again."
        ]
    ]
}

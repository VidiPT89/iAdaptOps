import Foundation

extension Translations {
    /// Names and coaching for the care exercises: seated, chair-supported or
    /// against a wall, for people whose bodies need a gentler start.
    static let care: [String: [Lang: String]] = [
        // MARK: Names
        "exercise.seatedMarch": [.pt: "Marcha sentada", .en: "Seated march"],
        "exercise.seatedKneeExtension": [.pt: "Extensão do joelho sentada", .en: "Seated knee extension"],
        "exercise.sitToStand": [.pt: "Sentar e levantar", .en: "Sit to stand"],
        "exercise.wallPushUp": [.pt: "Flexão na parede", .en: "Wall push-up"],
        "exercise.shoulderRolls": [.pt: "Rotação dos ombros", .en: "Shoulder rolls"],
        "exercise.diaphragmaticBreathing": [.pt: "Respiração diafragmática", .en: "Diaphragmatic breathing"],
        "exercise.seatedCatCow": [.pt: "Gato e vaca sentado", .en: "Seated cat-cow"],
        "exercise.seatedRotation": [.pt: "Rotação do tronco sentada", .en: "Seated trunk rotation"],
        "exercise.supportedBalance": [.pt: "Equilíbrio com apoio", .en: "Supported balance"],
        "exercise.standingHipAbduction": [.pt: "Abertura lateral da perna com apoio", .en: "Supported side leg lift"],

        // MARK: Seated march
        "cue.seatedMarch.steps": [
            .pt: "Senta-te na ponta da cadeira, costas direitas e pés no chão. Levanta um joelho de cada vez, sem pressa, como se marchasses.",
            .en: "Sit near the front of the chair, back tall, feet flat. Lift one knee at a time, unhurried, as if marching."
        ],
        "cue.seatedMarch.breathing": [
            .pt: "Respira de forma natural e ritmada.",
            .en: "Breathe naturally and steadily."
        ],
        "cue.seatedMarch.easier": [
            .pt: "Levanta só os calcanhares, alternando.",
            .en: "Lift only your heels, alternating."
        ],

        // MARK: Seated knee extension
        "cue.seatedKneeExtension.steps": [
            .pt: "Na cadeira, estica devagar uma perna até ficar quase direita, segura um instante e baixa com controlo. Alterna.",
            .en: "Seated, slowly straighten one leg until it is almost straight, hold for a moment and lower with control. Alternate."
        ],
        "cue.seatedKneeExtension.breathing": [
            .pt: "Expira a esticar, inspira a baixar.",
            .en: "Exhale as you straighten, inhale as you lower."
        ],
        "cue.seatedKneeExtension.easier": [
            .pt: "Estica só até meio caminho.",
            .en: "Straighten only halfway."
        ],

        // MARK: Sit to stand
        "cue.sitToStand.steps": [
            .pt: "Na cadeira, pés à largura da anca. Inclina o tronco à frente e levanta-te a empurrar o chão. Volta a sentar devagar, sem te deixares cair.",
            .en: "Seated, feet hip-width apart. Lean forward and stand up by pushing the floor away. Sit back down slowly, without dropping."
        ],
        "cue.sitToStand.breathing": [
            .pt: "Expira a levantar, inspira a sentar.",
            .en: "Exhale as you stand, inhale as you sit."
        ],
        "cue.sitToStand.easier": [
            .pt: "Usa as mãos nos joelhos ou nos braços da cadeira para ajudar.",
            .en: "Use your hands on your knees or on the chair's armrests to help."
        ],
        "cue.sitToStand.caution": [
            .pt: "Se tiveres tonturas ao levantar, faz uma pausa na cadeira antes de repetir.",
            .en: "If standing up makes you dizzy, pause seated before the next one."
        ],

        // MARK: Wall push-up
        "cue.wallPushUp.steps": [
            .pt: "De frente para a parede, mãos apoiadas à altura dos ombros. Dobra os cotovelos e aproxima o peito da parede, depois empurra de volta.",
            .en: "Facing the wall, hands flat at shoulder height. Bend your elbows to bring your chest towards the wall, then push back."
        ],
        "cue.wallPushUp.breathing": [
            .pt: "Inspira a aproximar, expira a empurrar.",
            .en: "Inhale as you lean in, exhale as you push away."
        ],
        "cue.wallPushUp.easier": [
            .pt: "Aproxima os pés da parede para inclinar menos.",
            .en: "Stand closer to the wall so you lean less."
        ],

        // MARK: Shoulder rolls
        "cue.shoulderRolls.steps": [
            .pt: "Na cadeira, braços relaxados. Desenha círculos lentos com os ombros, para trás e depois para a frente.",
            .en: "Seated, arms relaxed. Draw slow circles with your shoulders, backwards and then forwards."
        ],
        "cue.shoulderRolls.breathing": [
            .pt: "Inspira a subir os ombros, expira a descê-los.",
            .en: "Inhale as the shoulders rise, exhale as they drop."
        ],
        "cue.shoulderRolls.easier": [
            .pt: "Faz círculos mais pequenos, ou só sobe e desce os ombros.",
            .en: "Make smaller circles, or simply lift and lower your shoulders."
        ],

        // MARK: Diaphragmatic breathing
        "cue.diaphragmaticBreathing.steps": [
            .pt: "Na cadeira ou no tapete, uma mão na barriga. Inspira pelo nariz e sente a barriga subir; expira devagar pela boca e sente-a descer.",
            .en: "Sitting or lying down, one hand on your belly. Breathe in through the nose and feel the belly rise; breathe out slowly through the mouth and feel it fall."
        ],
        "cue.diaphragmaticBreathing.breathing": [
            .pt: "Conta 4 a inspirar e 6 a expirar.",
            .en: "Count 4 breathing in and 6 breathing out."
        ],
        "cue.diaphragmaticBreathing.easier": [
            .pt: "Respira ao teu ritmo, sem contar.",
            .en: "Breathe at your own pace, without counting."
        ],

        // MARK: Seated cat-cow
        "cue.seatedCatCow.steps": [
            .pt: "Na cadeira, mãos nos joelhos. Arredonda as costas e leva o queixo ao peito; depois abre o peito e olha ligeiramente para cima.",
            .en: "Seated, hands on your knees. Round your back and tuck your chin; then open your chest and look slightly up."
        ],
        "cue.seatedCatCow.breathing": [
            .pt: "Expira a arredondar, inspira a abrir o peito.",
            .en: "Exhale as you round, inhale as you open the chest."
        ],
        "cue.seatedCatCow.easier": [
            .pt: "Faz o movimento mais pequeno, só com a parte de cima das costas.",
            .en: "Keep the movement smaller, only through the upper back."
        ],

        // MARK: Seated rotation
        "cue.seatedRotation.steps": [
            .pt: "Na cadeira, braços cruzados no peito. Roda o tronco devagar para um lado, volta ao centro e roda para o outro.",
            .en: "Seated, arms crossed on your chest. Turn your trunk slowly to one side, come back to the centre and turn to the other."
        ],
        "cue.seatedRotation.breathing": [
            .pt: "Expira a rodar, inspira ao voltar.",
            .en: "Exhale as you turn, inhale as you come back."
        ],
        "cue.seatedRotation.easier": [
            .pt: "Roda só um pouco, sem forçar o fim do movimento.",
            .en: "Turn only a little, without pushing the end of the range."
        ],

        // MARK: Supported balance
        "cue.supportedBalance.steps": [
            .pt: "De pé atrás da cadeira, mãos no encosto. Levanta um pé poucos centímetros do chão e segura. Troca de lado a meio.",
            .en: "Stand behind the chair, hands on the backrest. Lift one foot a few centimetres off the floor and hold. Switch sides halfway."
        ],
        "cue.supportedBalance.breathing": [
            .pt: "Respira calmamente e fixa o olhar num ponto à frente.",
            .en: "Breathe calmly and fix your gaze on a point ahead."
        ],
        "cue.supportedBalance.easier": [
            .pt: "Deixa a ponta do pé tocar no chão.",
            .en: "Let the tip of your foot touch the floor."
        ],
        "cue.supportedBalance.caution": [
            .pt: "Mantém sempre as mãos na cadeira.",
            .en: "Keep your hands on the chair the whole time."
        ],

        // MARK: Supported side leg lift
        "cue.standingHipAbduction.steps": [
            .pt: "De pé com as mãos na cadeira, afasta uma perna para o lado sem inclinar o tronco e volta devagar. Troca de lado a meio.",
            .en: "Standing with your hands on the chair, move one leg out to the side without tilting your trunk and bring it back slowly. Switch sides halfway."
        ],
        "cue.standingHipAbduction.breathing": [
            .pt: "Expira a afastar, inspira a voltar.",
            .en: "Exhale as the leg goes out, inhale as it returns."
        ],
        "cue.standingHipAbduction.easier": [
            .pt: "Afasta a perna só um pouco.",
            .en: "Move the leg out only a little."
        ]
    ]
}

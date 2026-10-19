import Foundation

extension Translations {
    static let program: [String: [Lang: String]] = [
        // MARK: Structure
        "week.n": [.pt: "Semana %d", .en: "Week %d"],
        "day.n": [.pt: "Dia %d", .en: "Day %d"],
        "week.short": [.pt: "S%d", .en: "W%d"],
        "weekday.mon": [.pt: "Seg", .en: "Mon"],
        "weekday.tue": [.pt: "Ter", .en: "Tue"],
        "weekday.wed": [.pt: "Qua", .en: "Wed"],
        "weekday.thu": [.pt: "Qui", .en: "Thu"],
        "weekday.fri": [.pt: "Sex", .en: "Fri"],
        "weekday.sat": [.pt: "Sáb", .en: "Sat"],
        "weekday.sun": [.pt: "Dom", .en: "Sun"],

        "block.warmup": [.pt: "Aquecimento", .en: "Warm-up"],
        "block.workout": [.pt: "Treino", .en: "Workout"],
        "block.cooldown": [.pt: "Alongamentos", .en: "Stretching"],
        "params.work": [.pt: "Trabalho", .en: "Work"],
        "params.rest": [.pt: "Descanso", .en: "Rest"],
        "params.rounds": [.pt: "Voltas", .en: "Rounds"],
        "params.minutes": [.pt: "%d min", .en: "%d min"],

        // MARK: Phases
        "phase.foundation": [.pt: "Fundação", .en: "Foundation"],
        "phase.foundation.desc": [
            .pt: "Aprender os movimentos e ativar o abdómen profundo.",
            .en: "Learn the movements and activate the deep core."
        ],
        "phase.firming": [.pt: "Firmeza", .en: "Firming"],
        "phase.firming.desc": [
            .pt: "Mais firmeza nas coxas e glúteos.",
            .en: "More firmness in thighs and glutes."
        ],
        "phase.endurance": [.pt: "Resistência", .en: "Endurance"],
        "phase.endurance.desc": [
            .pt: "Mais resistência e definição.",
            .en: "More endurance and definition."
        ],
        "phase.consolidation": [.pt: "Consolidação", .en: "Consolidation"],
        "phase.consolidation.desc": [
            .pt: "Mais intensidade, sem saltos nem ginásio.",
            .en: "More intensity, no jumps, no gym."
        ],

        // MARK: Day titles
        "day.activateCoreLegs": [.pt: "Ativar barriga e pernas", .en: "Wake up core & legs"],
        "day.thighsGlutes": [.pt: "Coxas e glúteos", .en: "Thighs & glutes"],
        "day.postpartumCore": [.pt: "Core pós-parto", .en: "Postpartum core"],
        "day.fullBody": [.pt: "Corpo inteiro", .en: "Full body"],
        "day.controlRange": [.pt: "Controlo e amplitude", .en: "Control & range"],
        "day.pulsesActivation": [.pt: "Pulsos e ativação", .en: "Pulses & activation"],
        "day.firstLoad": [.pt: "Primeira carga", .en: "First load"],
        "day.loadedStrength": [.pt: "Força com carga", .en: "Loaded strength"],
        "day.finalChallenge": [.pt: "Desafio final", .en: "Final challenge"],

        "program.days": [.pt: "Dias", .en: "Days"],
        "day.locked": [.pt: "Conclui o dia anterior primeiro", .en: "Finish the previous day first"],
        "day.completed": [.pt: "Concluído", .en: "Completed"],

        // MARK: Modifiers
        "modifier.deeper": [.pt: "desce mais", .en: "go deeper"],
        "modifier.hold2s": [.pt: "segura 2 s", .en: "hold 2 s"],
        "modifier.hold1s": [.pt: "segura 1 s", .en: "hold 1 s"],
        "modifier.slow": [.pt: "lento", .en: "slow"],
        "modifier.pulse": [.pt: "com pulso", .en: "pulse"],
        "modifier.weighted": [.pt: "com garrafas", .en: "with bottles"],
        "modifier.deeper.desc": [
            .pt: "Maior amplitude, sempre com controlo.",
            .en: "A bigger range, always under control."
        ],
        "modifier.hold2s.desc": [
            .pt: "Pausa de 2 segundos no ponto mais alto.",
            .en: "Pause for 2 seconds at the top."
        ],
        "modifier.hold1s.desc": [
            .pt: "Pausa de 1 segundo no ponto mais alto.",
            .en: "Pause for 1 second at the top."
        ],
        "modifier.slow.desc": [
            .pt: "3 segundos a ir, 3 segundos a voltar.",
            .en: "3 seconds out, 3 seconds back."
        ],
        "modifier.pulse.desc": [
            .pt: "Pequenas oscilações na posição mais difícil.",
            .en: "Small pulses at the hardest position."
        ],
        "modifier.weighted.desc": [
            .pt: "Uma garrafa de água em cada mão, se te sentires bem.",
            .en: "One water bottle in each hand, if you feel up to it."
        ],

        // MARK: Session player
        "session.getReady": [.pt: "Prepara-te", .en: "Get ready"],
        "session.rest": [.pt: "Descanso", .en: "Rest"],
        "session.next": [.pt: "A seguir", .en: "Up next"],
        "session.switchSide": [.pt: "Troca de lado", .en: "Switch sides"],
        "session.round": [.pt: "Volta %d de %d", .en: "Round %d of %d"],
        "session.pause": [.pt: "Pausa", .en: "Pause"],
        "session.resume": [.pt: "Retomar", .en: "Resume"],
        "session.paused": [.pt: "Em pausa", .en: "Paused"],
        "session.stopRest": [.pt: "Parar e descansar", .en: "Stop and rest"],
        "session.done": [.pt: "Muito bem! Treino concluído", .en: "Well done! Workout complete"],
        "session.previousExercise": [.pt: "Exercício anterior", .en: "Previous exercise"],
        "session.nextExercise": [.pt: "Exercício seguinte", .en: "Next exercise"],
        "session.exitTitle": [.pt: "Terminar o treino?", .en: "End this workout?"],
        "session.exitBody": [
            .pt: "O dia fica por concluir. Podes voltar a começá-lo quando quiseres.",
            .en: "The day stays unfinished. You can start it again whenever you like."
        ],
        "session.exitConfirm": [.pt: "Terminar por hoje", .en: "End for today"],
        "session.switchToLowEnergy": [.pt: "Mudar para Dia difícil", .en: "Switch to Low-energy day"],
        "session.totalTime": [.pt: "Tempo total", .en: "Total time"],
        "session.finalTitle": [.pt: "Chegaste ao fim do programa!", .en: "You finished the program!"],
        "session.finalBody": [
            .pt: "28 sessões em 7 semanas. Obrigado por cuidares de ti.",
            .en: "28 sessions over 7 weeks. Thank you for taking care of yourself."
        ],
        "session.viewProgram": [.pt: "Ver programa", .en: "View program"],

        // MARK: Check-in
        "checkin.title": [.pt: "Como te sentes?", .en: "How do you feel?"],
        "checkin.optional": [.pt: "Opcional, guardado só na tua conta.", .en: "Optional, saved only to your account."],
        "checkin.energy": [.pt: "Como está a tua energia?", .en: "How is your energy?"],
        "checkin.discomfort": [.pt: "Algum desconforto?", .en: "Any discomfort?"],
        "checkin.note": [.pt: "Nota", .en: "Note"],
        "checkin.notePlaceholder": [.pt: "Algo que queiras registar", .en: "Anything you want to note down"],

        // MARK: Achievements
        "achievements.title": [.pt: "Conquistas", .en: "Achievements"],
        "achievement.firstWorkout": [.pt: "Primeiro treino", .en: "First workout"],
        "achievement.firstWeek": [.pt: "Semana 1 completa", .en: "Week 1 complete"],
        "achievement.halfway": [.pt: "Meio caminho", .en: "Halfway there"],
        "achievement.firstLoad": [.pt: "Primeira carga", .en: "First load"],
        "achievement.finalChallenge": [.pt: "Programa completo", .en: "Program complete"],

        // MARK: History
        "history.title": [.pt: "Histórico", .en: "History"],
        "history.empty": [
            .pt: "Ainda não há treinos registados. O primeiro aparece aqui assim que o concluíres.",
            .en: "No workouts logged yet. The first one shows up here as soon as you finish it."
        ],
        "history.deleteTitle": [.pt: "Apagar este treino?", .en: "Delete this workout?"],
        "history.deleteBody": [
            .pt: "Sai do histórico e do progresso. Não dá para desfazer.",
            .en: "It is removed from your history and progress. This cannot be undone."
        ],
        "history.energyLabel": [.pt: "Energia %d/5", .en: "Energy %d/5"],
        "history.discomfortLabel": [.pt: "Desconforto %d/10", .en: "Discomfort %d/10"],

        // MARK: Reminders and sharing
        "reminder.title": [.pt: "iAdaptOps", .en: "iAdaptOps"],
        "reminder.body": [
            .pt: "A tua sessão de cuidado está à tua espera 🧡",
            .en: "Your care session is waiting for you 🧡"
        ],
        "share.weekTitle": [.pt: "Partilhar a semana", .en: "Share this week"],
        "share.footer": [.pt: "iAdaptOps · ividi.dev", .en: "iAdaptOps · ividi.dev"]
    ]
}

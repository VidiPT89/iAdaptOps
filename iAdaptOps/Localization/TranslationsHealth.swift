import Foundation

extension Translations {
    /// The health questionnaire and the generated care plan.
    static let health: [String: [Lang: String]] = [
        // MARK: Questionnaire
        "health.title": [.pt: "Sobre ti", .en: "About you"],
        "health.intro": [
            .pt: "Com estas respostas a app monta um plano de cuidado à tua medida. Tudo é opcional e fica só na tua conta: nem o administrador as vê.",
            .en: "With these answers the app builds a care plan that suits you. Everything is optional and stays in your account only: not even the administrator sees it."
        ],
        "health.basics": [.pt: "Dados básicos", .en: "The basics"],
        "health.age": [.pt: "Idade", .en: "Age"],
        "health.weight": [.pt: "Peso (kg)", .en: "Weight (kg)"],
        "health.height": [.pt: "Altura (cm)", .en: "Height (cm)"],
        "health.conditions": [.pt: "Condições de saúde", .en: "Health conditions"],
        "health.conditionsHint": [.pt: "Escolhe todas as que se aplicam.", .en: "Choose all that apply."],
        "health.other": [.pt: "Outra condição (opcional)", .en: "Another condition (optional)"],
        "health.limitations": [.pt: "Hoje em dia", .en: "These days"],
        "health.limitationsHint": [
            .pt: "Marca o que costuma ser difícil. A app evita esses movimentos.",
            .en: "Tick what is usually hard. The app avoids those movements."
        ],
        "health.energy": [.pt: "Energia num dia normal", .en: "Energy on a typical day"],
        "health.energyLow": [.pt: "Muito pouca", .en: "Very little"],
        "health.energyHigh": [.pt: "Bastante", .en: "Plenty"],
        "health.activity": [.pt: "Atividade nos últimos meses", .en: "Activity in recent months"],
        "health.save": [.pt: "Guardar e atualizar o plano", .en: "Save and update my plan"],
        "health.edit": [.pt: "O meu perfil de saúde", .en: "My health profile"],
        "health.planPreview": [.pt: "O teu plano", .en: "Your plan"],
        "health.previewSeated": [.pt: "Sem exercícios no chão", .en: "No floor exercises"],
        "health.previewSupported": [.pt: "Equilíbrio sempre com apoio", .en: "Balance always with support"],
        "health.previewNoStanding": [.pt: "Sobretudo sentado ou deitado", .en: "Mostly seated or lying down"],
        "health.todayTitle": [.pt: "Personaliza o teu plano", .en: "Personalize your plan"],
        "health.todayBody": [
            .pt: "Responde a umas perguntas rápidas e a app ajusta os exercícios ao teu corpo.",
            .en: "Answer a few quick questions and the app adjusts the exercises to your body."
        ],
        "health.todayAction": [.pt: "Responder agora", .en: "Answer now"],

        // MARK: Conditions
        "condition.fibromyalgia": [.pt: "Fibromialgia", .en: "Fibromyalgia"],
        "condition.chronicFatigue": [.pt: "Encefalomielite miálgica / fadiga crónica", .en: "ME / chronic fatigue syndrome"],
        "condition.longCovid": [.pt: "COVID longa", .en: "Long COVID"],
        "condition.pots": [.pt: "Disautonomia / POTS", .en: "Dysautonomia / POTS"],
        "condition.inflammatoryArthritis": [.pt: "Artrite reumatoide ou inflamatória", .en: "Rheumatoid or inflammatory arthritis"],
        "condition.osteoarthritis": [.pt: "Artrose", .en: "Osteoarthritis"],
        "condition.lupus": [.pt: "Lúpus", .en: "Lupus"],
        "condition.behcet": [.pt: "Doença de Behçet", .en: "Behçet's disease"],
        "condition.hypermobility": [.pt: "Hipermobilidade / Ehlers-Danlos", .en: "Hypermobility / Ehlers-Danlos"],
        "condition.multipleSclerosis": [.pt: "Esclerose múltipla", .en: "Multiple sclerosis"],
        "condition.parkinsons": [.pt: "Doença de Parkinson", .en: "Parkinson's disease"],
        "condition.heartCondition": [.pt: "Doença cardíaca ou hipertensão", .en: "Heart condition or high blood pressure"],
        "condition.respiratory": [.pt: "Asma ou DPOC", .en: "Asthma or COPD"],
        "condition.diabetes": [.pt: "Diabetes", .en: "Diabetes"],
        "condition.bowelDisease": [.pt: "Doença inflamatória do intestino", .en: "Inflammatory bowel disease"],
        "condition.chronicBackPain": [.pt: "Dor lombar crónica", .en: "Chronic low back pain"],
        "condition.osteoporosis": [.pt: "Osteoporose", .en: "Osteoporosis"],
        "condition.cancer": [.pt: "Cancro (tratamento ou recuperação)", .en: "Cancer (treatment or recovery)"],
        "condition.postpartum": [.pt: "Pós-parto ou pós-cesariana", .en: "Postpartum or after a C-section"],

        // MARK: Limitations
        "limitation.kneePain": [.pt: "Dor nos joelhos", .en: "Knee pain"],
        "limitation.wristHandPain": [.pt: "Dor nos pulsos ou mãos", .en: "Wrist or hand pain"],
        "limitation.shoulderPain": [.pt: "Dor nos ombros", .en: "Shoulder pain"],
        "limitation.lowBackPain": [.pt: "Dor nas costas", .en: "Back pain"],
        "limitation.neckPain": [.pt: "Dor no pescoço", .en: "Neck pain"],
        "limitation.dizziness": [.pt: "Tonturas ou pouco equilíbrio", .en: "Dizziness or poor balance"],
        "limitation.cannotGetToFloor": [.pt: "Custa-me descer e subir do chão", .en: "Getting down to and up from the floor is hard"],
        "limitation.cannotStandLong": [.pt: "Custa-me estar muito tempo de pé", .en: "Standing for long is hard"],

        // MARK: Activity
        "activity.none": [.pt: "Quase nenhuma", .en: "Hardly any"],
        "activity.light": [.pt: "Caminhadas ou atividade leve", .en: "Walks or light activity"],
        "activity.regular": [.pt: "Exercício 2 ou mais vezes por semana", .en: "Exercise twice a week or more"],

        // MARK: Generated plan
        "tier.1": [.pt: "Plano personalizado · muito suave", .en: "Personalized plan · very gentle"],
        "tier.2": [.pt: "Plano personalizado · suave", .en: "Personalized plan · gentle"],
        "tier.3": [.pt: "Plano personalizado · moderado", .en: "Personalized plan · moderate"],
        "day.care.mobility": [.pt: "Mobilidade e respiração", .en: "Mobility & breathing"],
        "day.care.strength": [.pt: "Força suave", .en: "Gentle strength"],
        "day.care.core": [.pt: "Centro do corpo e respiração", .en: "Core & breathing"],
        "day.care.balance": [.pt: "Equilíbrio e corpo inteiro", .en: "Balance & full body"],
        "day.care.final": [.pt: "Sessão final", .en: "Final session"],
        "phase.care.start": [.pt: "Começar com calma", .en: "A calm start"],
        "phase.care.start.desc": [
            .pt: "Conhecer os movimentos e ouvir o corpo.",
            .en: "Get to know the movements and listen to your body."
        ],
        "phase.care.build": [.pt: "Ganhar confiança", .en: "Building confidence"],
        "phase.care.build.desc": [
            .pt: "Um pouco mais de tempo em cada exercício.",
            .en: "A little more time on each exercise."
        ],
        "phase.care.strength": [.pt: "Força suave", .en: "Gentle strength"],
        "phase.care.strength.desc": [
            .pt: "Mais força e mobilidade, sempre ao teu ritmo.",
            .en: "More strength and mobility, always at your pace."
        ],
        "phase.care.consolidate": [.pt: "Consolidar", .en: "Consolidating"],
        "phase.care.consolidate.desc": [
            .pt: "Manter o que ganhaste, sem pressa.",
            .en: "Keep what you have gained, without rushing."
        ]
    ]
}

import Foundation

extension Translations {
    /// Coaching text for every catalog exercise: how to do it, how to breathe,
    /// the mistake to watch for, the easier version and any caution.
    static let cues: [String: [Lang: String]] = {
        var merged = standingCues
        merged.merge(floorCues) { current, _ in current }
        return merged
    }()

    static let standingCues: [String: [Lang: String]] = [
        // MARK: March in place
        "cue.marchInPlace.steps": [
            .pt: "Marcha no lugar, joelhos à altura confortável, braços a acompanhar. Mantém o tronco direito e a barriga ligeiramente ativa.",
            .en: "March on the spot, knees to a comfortable height, arms swinging. Keep your torso tall and your belly gently engaged."
        ],
        "cue.marchInPlace.breathing": [
            .pt: "Respiração natural e ritmada.",
            .en: "Natural and steady breathing."
        ],
        "cue.marchInPlace.easier": [
            .pt: "Levanta só os calcanhares, sem subir os joelhos.",
            .en: "Lift only your heels, without raising your knees."
        ],

        // MARK: Gentle squat
        "cue.gentleSquat.steps": [
            .pt: "Pés à largura dos ombros, desce só até meio, como se te fosses sentar numa cadeira alta. Sobe a apertar os glúteos.",
            .en: "Feet shoulder-width apart, lower halfway as if sitting on a tall chair. Rise by squeezing your glutes."
        ],
        "cue.gentleSquat.breathing": [
            .pt: "Inspira a descer, expira a subir.",
            .en: "Inhale down, exhale up."
        ],
        "cue.gentleSquat.easier": [
            .pt: "Coloca a cadeira atrás e toca-lhe ao de leve em cada repetição.",
            .en: "Put the chair behind you and lightly tap it on each repetition."
        ],

        // MARK: Hip circles
        "cue.hipCircles.steps": [
            .pt: "Mãos na cintura, desenha círculos lentos com a anca. Muda de sentido a meio do tempo.",
            .en: "Hands on hips, draw slow circles with your pelvis. Switch direction halfway through."
        ],
        "cue.hipCircles.breathing": [
            .pt: "Respira devagar, sem acompanhar o movimento.",
            .en: "Breathe slowly, without syncing to the movement."
        ],
        "cue.hipCircles.easier": [
            .pt: "Círculos mais pequenos, com uma mão apoiada na cadeira.",
            .en: "Smaller circles, with one hand on the chair."
        ],

        // MARK: Arm swings
        "cue.armSwings.steps": [
            .pt: "Balança os braços à frente e atrás, depois cruza-os à frente do peito. Ombros relaxados.",
            .en: "Swing your arms forward and back, then cross them in front of your chest. Relax your shoulders."
        ],
        "cue.armSwings.breathing": [
            .pt: "Inspira a abrir, expira a cruzar.",
            .en: "Inhale as you open, exhale as you cross."
        ],
        "cue.armSwings.easier": [
            .pt: "Amplitude menor, sem passar dos ombros.",
            .en: "A smaller range, without going past your shoulders."
        ],

        // MARK: Sumo squat
        "cue.sumoSquat.steps": [
            .pt: "Pés mais afastados que os ombros, pontas viradas para fora. Desce com as costas direitas e os joelhos na direção dos pés. Sobe a empurrar o chão.",
            .en: "Feet wider than your shoulders, toes turned out. Lower with a straight back, knees tracking over your toes. Push the floor away to rise."
        ],
        "cue.sumoSquat.breathing": [
            .pt: "Inspira a descer, expira a subir.",
            .en: "Inhale down, exhale up."
        ],
        "cue.sumoSquat.mistake": [
            .pt: "Joelhos a fechar para dentro.",
            .en: "Knees caving inwards."
        ],
        "cue.sumoSquat.easier": [
            .pt: "Menor amplitude, com uma mão apoiada na cadeira.",
            .en: "A shorter range, with one hand on a chair."
        ],

        // MARK: Squat (pulse variant)
        "cue.squat.steps": [
            .pt: "Desce até ao ponto mais baixo confortável e faz pequenas oscilações de poucos centímetros, sem subir totalmente.",
            .en: "Lower to your lowest comfortable point and make small pulses of a few centimetres without fully standing."
        ],
        "cue.squat.breathing": [
            .pt: "Respira de forma contínua, sem prender.",
            .en: "Keep breathing continuously, never holding."
        ],
        "cue.squat.mistake": [
            .pt: "Subir até acima a cada pulso e perder a tensão.",
            .en: "Standing all the way up on each pulse and losing the tension."
        ],
        "cue.squat.easier": [
            .pt: "Pulsos mais altos, perto da posição de pé.",
            .en: "Pulse higher, closer to standing."
        ],

        // MARK: Short lunge
        "cue.shortLunge.steps": [
            .pt: "Dá um passo curto atrás e desce o joelho de trás só até meio. Volta e troca de perna. Usa a cadeira para equilíbrio.",
            .en: "Take a short step back and lower your back knee only halfway. Return and switch legs. Use the chair for balance."
        ],
        "cue.shortLunge.breathing": [
            .pt: "Inspira a descer, expira a voltar.",
            .en: "Inhale as you lower, exhale as you return."
        ],
        "cue.shortLunge.mistake": [
            .pt: "Inclinar o tronco à frente em vez de descer a anca.",
            .en: "Leaning your torso forward instead of dropping your hips."
        ],
        "cue.shortLunge.easier": [
            .pt: "Passo mais curto e as duas mãos na cadeira.",
            .en: "A shorter step and both hands on the chair."
        ],
        "cue.shortLunge.caution": [
            .pt: "Sem dor no joelho. Reduz a amplitude se houver desconforto articular.",
            .en: "No knee pain. Reduce the range if you feel any joint discomfort."
        ],

        // MARK: Alternating lunges
        "cue.alternatingLunge.steps": [
            .pt: "Igual ao afundo curto, com um passo um pouco maior e um ritmo contínuo, sempre a alternar de perna.",
            .en: "Like the short lunge, with a slightly bigger step and a continuous rhythm, always alternating legs."
        ],
        "cue.alternatingLunge.breathing": [
            .pt: "Inspira a descer, expira a voltar.",
            .en: "Inhale as you lower, exhale as you return."
        ],
        "cue.alternatingLunge.easier": [
            .pt: "Volta ao passo curto e apoia-te na cadeira.",
            .en: "Go back to the short step and hold the chair."
        ],
        "cue.alternatingLunge.caution": [
            .pt: "Se o equilíbrio falhar, mantém sempre uma mão apoiada.",
            .en: "If your balance wavers, keep one hand supported at all times."
        ],

        // MARK: Wall sit
        "cue.wallSit.steps": [
            .pt: "Costas encostadas à parede, desliza até os joelhos ficarem num ângulo confortável, nunca mais baixo que 90 graus. Mantém e respira.",
            .en: "Back against the wall, slide down until your knees reach a comfortable angle, never lower than 90 degrees. Hold and breathe."
        ],
        "cue.wallSit.breathing": [
            .pt: "Respira devagar e nunca prendas a respiração.",
            .en: "Breathe slowly and never hold your breath."
        ],
        "cue.wallSit.mistake": [
            .pt: "Prender a respiração para aguentar mais tempo.",
            .en: "Holding your breath to last longer."
        ],
        "cue.wallSit.easier": [
            .pt: "Ângulo mais aberto, ficando mais alta na parede.",
            .en: "A more open angle, staying higher up the wall."
        ],

        // MARK: Calf raises
        "cue.calfRaise.steps": [
            .pt: "Mãos no encosto da cadeira, sobe em pontas de pés devagar e desce com controlo até ao chão.",
            .en: "Hands on the back of a chair, rise slowly onto your toes and lower with control to the floor."
        ],
        "cue.calfRaise.breathing": [
            .pt: "Expira a subir, inspira a descer.",
            .en: "Exhale up, inhale down."
        ],
        "cue.calfRaise.mistake": [
            .pt: "Deixar cair o calcanhar de repente.",
            .en: "Dropping your heels suddenly."
        ],
        "cue.calfRaise.easier": [
            .pt: "Sobe menos e apoia mais peso nas mãos.",
            .en: "Rise less and put more weight on your hands."
        ],

        // MARK: Side-lying leg raise
        "cue.sideLegRaise.steps": [
            .pt: "Deita-te de lado, cabeça apoiada no braço, perna de baixo fletida. Sobe a perna de cima esticada, sem rodar a anca para trás.",
            .en: "Lying on your side, head resting on your arm, bottom leg bent. Lift your straight top leg without rolling your hips back."
        ],
        "cue.sideLegRaise.breathing": [
            .pt: "Expira a subir a perna, inspira a descer.",
            .en: "Exhale as the leg rises, inhale as it lowers."
        ],
        "cue.sideLegRaise.mistake": [
            .pt: "Rodar a anca para trás e usar o flexor em vez do glúteo.",
            .en: "Rolling the hip back and using the hip flexor instead of the glute."
        ],
        "cue.sideLegRaise.easier": [
            .pt: "Amplitude menor, subindo só alguns centímetros.",
            .en: "A smaller range, lifting just a few centimetres."
        ]
    ]
}

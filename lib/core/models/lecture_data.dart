class SimulatedLecture {
  final String id;
  final String topic;
  final String course;
  final String professor;
  final List<String> transcriptChunks;

  const SimulatedLecture({
    required this.id,
    required this.topic,
    required this.course,
    required this.professor,
    required this.transcriptChunks,
  });
}

const List<SimulatedLecture> kSimulatedLectures = [
  SimulatedLecture(
    id: 'cybersecurity-zero-trust',
    topic: 'Zero Trust Architecture & Enterprise Defense',
    course: 'CS 475: Advanced Network Security',
    professor: 'Dr. Sarah Vance',
    transcriptChunks: [
      "Welcome everyone. Today we are dismantling the traditional perimeter defense model, often called the 'castle-and-moat' paradigm, and diving into Zero Trust Architecture.",
      "The foundational tenet of Zero Trust is deceptively simple: 'Never Trust, Always Verify.' Every request, whether originating inside or outside the network perimeter, must be authenticated and authorized.",
      "Consider identity as the primary perimeter. Instead of relying on firewall IP boundaries, we utilize Multi-Factor Authentication, device health telemetry, and strict identity assertion using protocols like OAuth 2.0 and mutual TLS.",
      "A core mechanism here is the Principle of Least Privilege (PoLP). Users and workloads receive only the absolute minimum permissions required to execute their specific task, strictly time-bounded through Just-In-Time access tokens.",
      "Let's talk about Micro-segmentation. In a legacy flat network, an attacker compromising a single internal web server can pivot laterally across the entire datacenter. With micro-segmentation, granular firewall rules isolate individual workloads, choking off lateral traversal.",
      "Another critical pillar is Continuous Real-Time Risk Analytics. Machine learning models evaluate behavioral anomalies—such as an engineering lead attempting to download customer databases from an unrecognized IP in an uncommon timezone.",
      "To summarize our key exam takeaway: Zero Trust is not a single software product. It is a comprehensive security philosophy combining Identity Governance, Micro-segmentation, Least Privilege, and Continuous Verification.",
    ],
  ),
  SimulatedLecture(
    id: 'quantum-computing',
    topic: 'Quantum Computing & Superposition Algorithms',
    course: 'PHYS 520: Quantum Information Science',
    professor: 'Prof. Alexei Rostov',
    transcriptChunks: [
      "Good morning class. Today we transition from classical Turing machines to the mind-bending principles governing Quantum Computing.",
      "In classical computing, a bit is deterministic: strictly 0 or 1. A qubit, however, exists in a linear superposition of both basis states: |ψ⟩ = α|0⟩ + β|1⟩, where the sum of probabilities |α|² + |β|² equals 1.",
      "This property allows a quantum register of n qubits to represent 2 to the power of n states simultaneously. But remember, the moment we measure the system, the wave function collapses to a single deterministic state.",
      "Next, let's explore Quantum Entanglement. Einstein famously questioned this as 'spooky action at a distance.' When two qubits become entangled, the measurement of one instantly determines the state of the other, regardless of spatial separation.",
      "Where does quantum advantage actually manifest? Look at Shor's Algorithm. Shor's can factor large composite integers in polynomial time O((log N)³), fundamentally threatening classical RSA public-key cryptography.",
      "Simultaneously, Grover's Algorithm provides a quadratic speedup for unstructured database searches, reducing search complexity from O(N) to O(√N).",
      "The paramount challenge confronting quantum engineers today is Quantum Decoherence—environmental noise destroying delicate phase coherence. This is why topological qubits and Quantum Error Correction codes are the holy grail of physical hardware.",
    ],
  ),
  SimulatedLecture(
    id: 'behavioral-economics',
    topic: 'Behavioral Economics & Choice Architecture',
    course: 'ECON 310: Microeconomic Decision Theory',
    professor: 'Dr. Elena Rostova',
    transcriptChunks: [
      "Welcome. Classical economics assumes 'Homo Economicus'—a perfectly rational agent with infinite cognitive bandwidth maximizing expected utility. Real human psychology tells a radically different story.",
      "Daniel Kahneman and Amos Tversky revolutionized the field with Prospect Theory. The fundamental finding: human beings are fundamentally loss averse. In empirical experiments, the psychological pain of losing \$100 is roughly twice as intense as the joy of gaining \$100.",
      "Another cognitive heuristic is the Framing Effect. Presenting a medical surgery with a '90% survival rate' leads to vastly higher patient consent than presenting it with a '10% mortality rate,' even though the mathematical reality is identical.",
      "Let us examine Choice Architecture and Nudge Theory, popularized by Richard Thaler. The way choices are structured inevitably alters human behavior without forbidding any options or altering economic incentives.",
      "A famous example is Default Biases in organ donation. Countries requiring citizens to opt-out of organ donation register over 90% consent rates, while opt-in countries struggle below 15%. Humans stick to default paths due to decision inertia.",
      "Finally, consider Temporal Discounting and Hyperbolic Discounting. Humans systematically overvalue immediate rewards relative to future payouts, explaining widespread under-saving for retirement despite rational awareness.",
    ],
  ),
];

import Foundation

// MARK: - Model

struct SystemStats {
    var cpu: Double = 0
    var memoryUsed: UInt64 = 0
    var memoryTotal: UInt64 = 0
    var thermalState: String = "Nominal"
    var powerSource: String = "AC"

    var topCPUName: String = "--"
    var topMemName: String = "--"
    var topEnergyName: String = "--"

    var memoryPercent: Double {
        guard memoryTotal > 0 else { return 0 }
        return Double(memoryUsed) / Double(memoryTotal) * 100
    }

    var cpuString: String { String(format: "%.0f%%", cpu) }
}

// MARK: - Service

final class SystemMonitorService: ObservableObject {
    static let shared = SystemMonitorService()

    @Published var stats = SystemStats()
    private var timer: Timer?

    private init() {}

    func start() {
        guard timer == nil else { return }
        fetch()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.fetch()
        }
    }

    func stop() { timer?.invalidate(); timer = nil }

    private func fetch() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let cpu = self.readCPU()
            let (used, total) = self.readMemory()
            let thermal = self.readThermalState()
            let power = self.readPowerSource()
            let topCPU = self.topProcess(sort: "cpu")
            let topMem = self.topProcess(sort: "mem")

            DispatchQueue.main.async {
                self.stats = SystemStats(
                    cpu: cpu,
                    memoryUsed: used,
                    memoryTotal: total,
                    thermalState: thermal,
                    powerSource: power,
                    topCPUName: topCPU,
                    topMemName: topMem,
                    topEnergyName: topCPU
                )
            }
        }
    }

    // MARK: - CPU (host_processor_info)

    private var prevTicks: [integer_t]?
    private var cpuCoreCount: natural_t = 0

    private func readCPU() -> Double {
        var count: mach_msg_type_number_t = 0
        var info: processor_info_array_t?
        var coreCount: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &coreCount,
            &info,
            &count
        )

        guard result == KERN_SUCCESS, let rawInfo = info else { return 0 }
        cpuCoreCount = coreCount

        let ticks = Array(UnsafeBufferPointer(start: rawInfo, count: Int(count)))

        // Free the kernel-allocated memory
        let size = vm_size_t(Int(count) * MemoryLayout<integer_t>.size)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: rawInfo), size)

        guard let prev = prevTicks, prev.count == ticks.count else {
            prevTicks = ticks
            return 0
        }

        var totalDelta: Double = 0
        var idleDelta: Double = 0
        let perCore = Int(count) / Int(coreCount)

        for i in 0..<Int(coreCount) {
            let off = i * perCore
            // ticks per core: [user, system, idle, nice]
            guard off + 3 < ticks.count, off + 3 < prev.count else { continue }
            let dUser   = Double(ticks[off + 0] - prev[off + 0])
            let dSys    = Double(ticks[off + 1] - prev[off + 1])
            let dIdle   = Double(ticks[off + 2] - prev[off + 2])
            let dNice   = Double(ticks[off + 3] - prev[off + 3])
            totalDelta += dUser + dSys + dIdle + dNice
            idleDelta  += dIdle
        }

        prevTicks = ticks

        guard totalDelta > 0 else { return 0 }
        return (1.0 - idleDelta / totalDelta) * 100
    }

    // MARK: - Memory

    private func readMemory() -> (used: UInt64, total: UInt64) {
        let total = ProcessInfo.processInfo.physicalMemory
        var vmStat = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / 4)

        let result = withUnsafeMutablePointer(to: &vmStat) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, total) }
        let pageSize = UInt64(vm_kernel_page_size)
        let used = UInt64(vmStat.active_count + vmStat.inactive_count + vmStat.wire_count) * pageSize
        return (used, total)
    }

    // MARK: - Thermal

    private func readThermalState() -> String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:  return "Nominal"
        case .fair:     return "Fair"
        case .serious:  return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Nominal"
        }
    }

    // MARK: - Power Source (pmset)

    private func readPowerSource() -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["-g", "batt"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return "AC" }
            // "Now drawing from 'AC Power'" or
            // " -InternalBattery-0 (id=...) 85%; charging; ..."
            for line in output.components(separatedBy: "\n") {
                if line.contains("AC Power") { return "AC" }
                if line.contains("InternalBattery") || line.contains("Battery") {
                    let parts = line.components(separatedBy: ";")
                    if parts.count >= 2 {
                        let pct = parts[0].components(separatedBy: .whitespaces).last ?? ""
                        let status = parts[1].trimmingCharacters(in: .whitespaces)
                        if status == "charging" { return "⚡\(pct)" }
                        return "🔋\(pct)"
                    }
                }
            }
            return "AC"
        } catch {
            return "AC"
        }
    }

    // MARK: - Top Process

    private func topProcess(sort: String) -> String {
        let col = sort == "mem" ? "rss" : "pcpu"
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-A", "-o", "comm", "-o", col, "-r"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return "--" }
            for line in output.components(separatedBy: "\n").dropFirst() {
                let t = line.trimmingCharacters(in: .whitespaces)
                guard !t.isEmpty else { continue }
                // Format: "COMMAND       VALUE"
                let parts = t.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                guard parts.count >= 1, let name = parts.first, !name.isEmpty else { continue }
                if name == "ps" || name == "kernel_task" { continue }
                return String(name.prefix(16))
            }
        } catch {}
        return "--"
    }
}

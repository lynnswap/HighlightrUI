import ObservationsCompat
import Testing
@testable import HighlightrUICore

@MainActor
@Suite(.serialized)
struct HighlightrEditorModelStreamTests {
    @Test
    func snapshotStreamEmitsInitialSnapshot() async {
        let model = HighlightrEditorModel(text: "initial", language: "swift")

        let values = await collectValues(from: model.snapshotStream(backend: .legacy), count: 1)

        #expect(values.map(\.text) == ["initial"])
    }

    @Test
    func snapshotStreamSuppressesConsecutiveDuplicates() async {
        let model = HighlightrEditorModel(text: "", language: "swift")

        let task = Task { [model] in
            await collectValues(from: model.snapshotStream(backend: .legacy), count: 3)
        }

        await AsyncDrain.firstTurn()
        model.text = "print(1)"
        await AsyncDrain.firstTurn()
        model.text = "print(1)"
        await AsyncDrain.firstTurn()
        model.language = "javascript"

        let values = await task.value

        #expect(values.map(\.text) == ["", "print(1)", "print(1)"])
        #expect(values.map(\.language.rawValue) == ["swift", "swift", "javascript"])
    }

    @Test
    func snapshotStreamEmitsTextChanges() async {
        let model = HighlightrEditorModel(text: "a", language: "swift")

        let task = Task { [model] in
            await collectValues(from: model.snapshotStream(backend: .legacy), count: 2)
        }

        await AsyncDrain.firstTurn()
        model.text = "b"

        let values = await task.value

        #expect(values.map(\.text) == ["a", "b"])
    }

    @Test
    func snapshotStreamEmitsLanguageChanges() async {
        let model = HighlightrEditorModel(text: "a", language: "swift")

        let task = Task { [model] in
            await collectValues(from: model.snapshotStream(backend: .legacy), count: 2)
        }

        await AsyncDrain.firstTurn()
        model.language = "json"

        let values = await task.value

        #expect(values.map(\.language.rawValue) == ["swift", "json"])
    }

    @Test
    func snapshotStreamEmitsThemeChanges() async {
        let model = HighlightrEditorModel(text: "a", language: "swift")

        let task = Task { [model] in
            await collectValues(from: model.snapshotStream(backend: .legacy), count: 2)
        }

        await AsyncDrain.firstTurn()
        model.theme = .named("github")

        let values = await task.value

        #expect(values.map(\.theme) == [.automatic(light: "paraiso-light", dark: "paraiso-dark"), .named("github")])
    }

    @Test
    func snapshotStreamEmitsSelectionChanges() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")

        let task = Task { [model] in
            await collectValues(from: model.snapshotStream(backend: .legacy), count: 2)
        }

        await AsyncDrain.firstTurn()
        model.selection = TextSelection(location: 1, length: 2)

        let values = await task.value

        #expect(values.map(\.selection) == [.zero, TextSelection(location: 1, length: 2)])
    }

    @Test
    func snapshotStreamEmitsEditableChanges() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")

        let task = Task { [model] in
            await collectValues(from: model.snapshotStream(backend: .legacy), count: 2)
        }

        await AsyncDrain.firstTurn()
        model.isEditable = false

        let values = await task.value

        #expect(values.map(\.isEditable) == [true, false])
    }

    @Test
    func snapshotStreamEmitsFocusedChanges() async {
        let model = HighlightrEditorModel(text: "abc", language: "swift")

        let task = Task { [model] in
            await collectValues(from: model.snapshotStream(backend: .legacy), count: 2)
        }

        await AsyncDrain.firstTurn()
        model.isFocused = true

        let values = await task.value

        #expect(values.map(\.isFocused) == [false, true])
    }

    @Test
    func textStreamEmitsInitialAndUpdates() async {
        let model = HighlightrEditorModel(text: "a", language: "swift")

        let task = Task { [model] in
            await collectValues(from: model.textStream(backend: .legacy), count: 3)
        }

        await AsyncDrain.firstTurn()
        model.text = "b"
        await AsyncDrain.firstTurn()
        model.text = "c"

        let values = await task.value

        #expect(values == ["a", "b", "c"])
    }

    @Test
    func textStreamSuppressesConsecutiveDuplicates() async {
        let model = HighlightrEditorModel(text: "a", language: "swift")

        let task = Task { [model] in
            await collectValues(from: model.textStream(backend: .legacy), count: 3)
        }

        await AsyncDrain.firstTurn()
        model.text = "b"
        await AsyncDrain.firstTurn()
        model.text = "b"
        await AsyncDrain.firstTurn()
        model.text = "c"

        let values = await task.value

        #expect(values == ["a", "b", "c"])
    }

    @Test
    func themeStreamEmitsInitialAndUpdates() async {
        let model = HighlightrEditorModel(text: "a", language: "swift")

        let task = Task { [model] in
            await collectValues(from: model.themeStream(backend: .legacy), count: 3)
        }

        await AsyncDrain.firstTurn()
        model.theme = .named("github")
        await AsyncDrain.firstTurn()
        model.theme = .named("atom-one-dark")

        let values = await task.value

        #expect(values == [
            .automatic(light: "paraiso-light", dark: "paraiso-dark"),
            .named("github"),
            .named("atom-one-dark"),
        ])
    }

    @Test
    func themeStreamSuppressesConsecutiveDuplicates() async {
        let model = HighlightrEditorModel(text: "a", language: "swift")

        let task = Task { [model] in
            await collectValues(from: model.themeStream(backend: .legacy), count: 3)
        }

        await AsyncDrain.firstTurn()
        model.theme = .named("github")
        await AsyncDrain.firstTurn()
        model.theme = .named("github")
        await AsyncDrain.firstTurn()
        model.theme = .named("atom-one-dark")

        let values = await task.value

        #expect(values == [
            .automatic(light: "paraiso-light", dark: "paraiso-dark"),
            .named("github"),
            .named("atom-one-dark"),
        ])
    }

    private func collectValues<T: Sendable>(
        from stream: ObservationsCompatStream<T>,
        count: Int,
        timeoutNanoseconds: UInt64 = 3_000_000_000
    ) async -> [T] {
        await withTaskGroup(of: [T].self) { group in
            group.addTask {
                var values: [T] = []
                var iterator = stream.makeAsyncIterator()

                while values.count < count {
                    guard let value = await iterator.next() else { break }
                    values.append(value)
                }

                return values
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                return []
            }

            let result = await group.next() ?? []
            group.cancelAll()
            return result
        }
    }
}

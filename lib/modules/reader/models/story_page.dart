/// Modelos e máquina de estado da aventura interactiva.
///
/// Espelha `luditeca-vps/frontend/lib/interactiveAdventure.js` para garantir
/// paridade com o leitor web e com o save state em SharedPreferences (mesma
/// chave/schema do projeto Play, para futura interoperabilidade).
library;

class Effects {
  final Map<String, bool> setFlags;
  final List<String> clearFlags;
  final List<String> addItems;
  final List<String> removeItems;

  const Effects({
    this.setFlags = const {},
    this.clearFlags = const [],
    this.addItems = const [],
    this.removeItems = const [],
  });

  bool get isEmpty =>
      setFlags.isEmpty &&
      clearFlags.isEmpty &&
      addItems.isEmpty &&
      removeItems.isEmpty;

  factory Effects.fromJson(Map<String, dynamic> json) {
    Map<String, bool> readBoolMap(dynamic raw) {
      if (raw is! Map) return const {};
      final out = <String, bool>{};
      raw.forEach((key, value) {
        if (key == null) return;
        out['$key'] = value == true;
      });
      return out;
    }

    List<String> readStringList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .where((v) => v != null)
          .map((v) => v.toString())
          .where((v) => v.isNotEmpty)
          .toList(growable: false);
    }

    return Effects(
      setFlags: readBoolMap(json['set_flags']),
      clearFlags: readStringList(json['clear_flags']),
      addItems: readStringList(json['add_items']),
      removeItems: readStringList(json['remove_items']),
    );
  }
}

class Conditions {
  final Map<String, bool> flagsAll;
  final Map<String, bool> flagsAny;
  final List<String> requiresItems;
  final List<String> excludesItems;
  final int? minVisitedPageId;

  const Conditions({
    this.flagsAll = const {},
    this.flagsAny = const {},
    this.requiresItems = const [],
    this.excludesItems = const [],
    this.minVisitedPageId,
  });

  bool get isEmpty =>
      flagsAll.isEmpty &&
      flagsAny.isEmpty &&
      requiresItems.isEmpty &&
      excludesItems.isEmpty &&
      minVisitedPageId == null;

  factory Conditions.fromJson(Map<String, dynamic> json) {
    Map<String, bool> readBoolMap(dynamic raw) {
      if (raw is! Map) return const {};
      final out = <String, bool>{};
      raw.forEach((key, value) {
        if (key == null) return;
        out['$key'] = value == true;
      });
      return out;
    }

    List<String> readStringList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .where((v) => v != null)
          .map((v) => v.toString())
          .where((v) => v.isNotEmpty)
          .toList(growable: false);
    }

    final all = json['flags_all'] ?? json['flags'];
    final minVisitedRaw = json['min_visited_page_id'];
    final minVisited = minVisitedRaw is num
        ? minVisitedRaw.toInt()
        : int.tryParse('${minVisitedRaw ?? ''}');

    return Conditions(
      flagsAll: readBoolMap(all),
      flagsAny: readBoolMap(json['flags_any']),
      requiresItems: readStringList(json['requires_items']),
      excludesItems: readStringList(json['excludes_items']),
      minVisitedPageId: minVisited,
    );
  }
}

class Choice {
  final String label;
  final int? targetPageId;
  final Conditions? conditions;
  final Effects? effects;

  const Choice({
    required this.label,
    this.targetPageId,
    this.conditions,
    this.effects,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      label: (json['label'] ?? '').toString(),
      targetPageId: _parsePageRef(
        json['target_page_id'] ?? json['target_scene_id'],
      ),
      conditions: json['conditions'] is Map
          ? Conditions.fromJson(
              Map<String, dynamic>.from(json['conditions'] as Map),
            )
          : null,
      effects: json['effects'] is Map
          ? Effects.fromJson(
              Map<String, dynamic>.from(json['effects'] as Map),
            )
          : null,
    );
  }
}

class StoryPage {
  final int id;
  final String? sceneTitle;
  final String? text;
  final String? imageUrl;
  final bool isStart;
  final bool isEnding;
  final String? endingType;
  final List<Choice> choices;
  final Effects? onEnter;

  const StoryPage({
    required this.id,
    this.sceneTitle,
    this.text,
    this.imageUrl,
    this.isStart = false,
    this.isEnding = false,
    this.endingType,
    this.choices = const [],
    this.onEnter,
  });

  factory StoryPage.fromJson(Map<String, dynamic> json, int fallbackId) {
    final id = _parsePageRef(json['page_id'] ?? json['scene_id']) ?? fallbackId;
    final choices = <Choice>[];
    final rawChoices = json['choices'];
    if (rawChoices is List) {
      for (final c in rawChoices) {
        if (c is Map) {
          choices.add(Choice.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }
    return StoryPage(
      id: id,
      sceneTitle: (json['scene_title'] ?? '').toString().trim().isEmpty
          ? null
          : (json['scene_title'] as Object).toString(),
      text: (json['text'] ?? '').toString().trim().isEmpty
          ? null
          : (json['text'] as Object).toString(),
      imageUrl: (json['image_url'] ?? '').toString().trim().isEmpty
          ? null
          : (json['image_url'] as Object).toString().trim(),
      isStart: json['is_start'] == true,
      isEnding: json['is_ending'] == true,
      endingType: (json['ending_type'] ?? '').toString().trim().isEmpty
          ? null
          : (json['ending_type'] as Object).toString(),
      choices: choices,
      onEnter: json['on_enter'] is Map
          ? Effects.fromJson(Map<String, dynamic>.from(json['on_enter'] as Map))
          : null,
    );
  }
}

class RunState {
  final String bookId;
  final int? currentPageId;
  final Map<String, bool> flags;
  final List<String> inventory;
  final List<int> history;
  final List<int> visitedPageIds;
  final String savedAt;

  const RunState({
    required this.bookId,
    required this.currentPageId,
    required this.flags,
    required this.inventory,
    required this.history,
    required this.visitedPageIds,
    required this.savedAt,
  });

  RunState copyWith({
    int? currentPageId,
    Map<String, bool>? flags,
    List<String>? inventory,
    List<int>? history,
    List<int>? visitedPageIds,
    String? savedAt,
  }) {
    return RunState(
      bookId: bookId,
      currentPageId: currentPageId ?? this.currentPageId,
      flags: flags ?? this.flags,
      inventory: inventory ?? this.inventory,
      history: history ?? this.history,
      visitedPageIds: visitedPageIds ?? this.visitedPageIds,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'currentPageId': currentPageId,
        'flags': flags,
        'inventory': inventory,
        'history': history,
        'visitedPageIds': visitedPageIds,
        'savedAt': savedAt,
      };

  factory RunState.fromJson(Map<String, dynamic> json) {
    Map<String, bool> readBoolMap(dynamic raw) {
      if (raw is! Map) return {};
      final out = <String, bool>{};
      raw.forEach((key, value) {
        if (key == null) return;
        out['$key'] = value == true;
      });
      return out;
    }

    List<int> readIntList(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .map((v) => v is int ? v : int.tryParse('${v ?? ''}'))
          .whereType<int>()
          .toList();
    }

    List<String> readStringList(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .where((v) => v != null)
          .map((v) => v.toString())
          .where((v) => v.isNotEmpty)
          .toList();
    }

    return RunState(
      bookId: (json['bookId'] ?? '').toString(),
      currentPageId: _parsePageRef(json['currentPageId']),
      flags: readBoolMap(json['flags']),
      inventory: readStringList(json['inventory']),
      history: readIntList(json['history']),
      visitedPageIds: readIntList(json['visitedPageIds']),
      savedAt: (json['savedAt'] ?? '').toString(),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers (extracção, identificação e máquina de estado)
// ---------------------------------------------------------------------------

int? _parsePageRef(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  if (s.startsWith('scene_')) {
    return int.tryParse(s.substring('scene_'.length));
  }
  return int.tryParse(s);
}

bool _isMetaRow(Map<String, dynamic> page) =>
    (page['page_type'] ?? '').toString().toLowerCase() == 'interactive_meta';

bool _isQuizRow(Map<String, dynamic> page) =>
    (page['page_type'] ?? '').toString().toLowerCase() == 'quiz';

/// Devolve apenas as páginas de história (sem meta, sem quiz).
/// Inclui atribuição de ID único quando faltar e marca a primeira como `is_start`
/// se nenhuma estiver marcada — equivalente a `normalizeAdventurePages` do JS.
List<StoryPage> extractStoryPages(List<Map<String, dynamic>> rawPages) {
  final raw = [...rawPages.where((p) => !_isMetaRow(p) && !_isQuizRow(p))];
  final used = <int>{};
  final assignedIds = <int>[];

  for (var i = 0; i < raw.length; i++) {
    final page = raw[i];
    int? id = _parsePageRef(page['page_id'] ?? page['scene_id']);
    if (id == null || used.contains(id)) {
      var next = 1;
      while (used.contains(next)) {
        next += 1;
      }
      id = next;
    }
    used.add(id);
    assignedIds.add(id);
  }

  final hasExplicitStart = raw.any((p) => p['is_start'] == true);

  final pages = <StoryPage>[];
  for (var i = 0; i < raw.length; i++) {
    final assignedId = assignedIds[i];
    final page = Map<String, dynamic>.from(raw[i]);
    page['page_id'] = assignedId;
    page['scene_id'] = '$assignedId';
    if (!hasExplicitStart && i == 0) page['is_start'] = true;
    pages.add(StoryPage.fromJson(page, assignedId));
  }

  // Re-aponta escolhas para IDs válidos (descarta destinos inexistentes).
  final validIds = pages.map((p) => p.id).toSet();
  return pages
      .map(
        (p) => StoryPage(
          id: p.id,
          sceneTitle: p.sceneTitle,
          text: p.text,
          imageUrl: p.imageUrl,
          isStart: p.isStart,
          isEnding: p.isEnding,
          endingType: p.endingType,
          onEnter: p.onEnter,
          choices: p.choices
              .map(
                (c) => Choice(
                  label: c.label,
                  targetPageId:
                      (c.targetPageId != null && validIds.contains(c.targetPageId))
                          ? c.targetPageId
                          : null,
                  conditions: c.conditions,
                  effects: c.effects,
                ),
              )
              .toList(),
        ),
      )
      .toList(growable: false);
}

Map<int, StoryPage> buildPageIndex(List<StoryPage> story) {
  return {for (final p in story) p.id: p};
}

int? getStartPageId(List<StoryPage> story) {
  if (story.isEmpty) return null;
  final start = story.firstWhere(
    (p) => p.isStart,
    orElse: () => story.first,
  );
  return start.id;
}

bool choiceMeetsConditions(
  RunState state,
  Conditions? conditions,
  Map<int, StoryPage> pageIndex,
) {
  if (conditions == null || conditions.isEmpty) return true;

  for (final entry in conditions.flagsAll.entries) {
    if (entry.value && state.flags[entry.key] != true) return false;
  }

  if (conditions.flagsAny.isNotEmpty) {
    final keys =
        conditions.flagsAny.entries.where((e) => e.value).map((e) => e.key);
    if (keys.isNotEmpty && !keys.any((k) => state.flags[k] == true)) {
      return false;
    }
  }

  for (final item in conditions.requiresItems) {
    if (!state.inventory.contains(item)) return false;
  }
  for (final item in conditions.excludesItems) {
    if (state.inventory.contains(item)) return false;
  }
  if (conditions.minVisitedPageId != null &&
      !pageIndex.containsKey(conditions.minVisitedPageId)) {
    return false;
  }
  return true;
}

List<Choice> getAvailableChoices(
  StoryPage page,
  RunState state,
  Map<int, StoryPage> pageIndex,
) {
  return page.choices
      .where((c) =>
          c.targetPageId != null &&
          pageIndex.containsKey(c.targetPageId) &&
          choiceMeetsConditions(state, c.conditions, pageIndex))
      .toList(growable: false);
}

RunState applyEffects(RunState state, Effects? effects) {
  if (effects == null || effects.isEmpty) return state;
  final flags = Map<String, bool>.from(state.flags);
  effects.setFlags.forEach((k, v) {
    flags[k] = v;
  });
  for (final k in effects.clearFlags) {
    flags.remove(k);
  }
  final inv = {...state.inventory};
  for (final i in effects.addItems) {
    inv.add(i);
  }
  for (final i in effects.removeItems) {
    inv.remove(i);
  }
  return state.copyWith(flags: flags, inventory: inv.toList());
}

RunState applyPageEnter(RunState state, StoryPage page) {
  return applyEffects(state, page.onEnter);
}

RunState createInitialRunState(String bookId, List<StoryPage> story) {
  final index = buildPageIndex(story);
  final startId = getStartPageId(story);
  final startPage = startId != null ? index[startId] : null;
  var state = RunState(
    bookId: bookId,
    currentPageId: startId,
    flags: const {},
    inventory: const [],
    history: startId != null ? [startId] : const [],
    visitedPageIds: startId != null ? [startId] : const [],
    savedAt: DateTime.now().toIso8601String(),
  );
  if (startPage != null) state = applyPageEnter(state, startPage);
  return state;
}

RunState navigateToPage(
  RunState state,
  int targetPageId,
  List<StoryPage> story,
) {
  final index = buildPageIndex(story);
  final page = index[targetPageId];
  if (page == null) return state;
  final visited = {...state.visitedPageIds, targetPageId}.toList();
  var next = state.copyWith(
    currentPageId: targetPageId,
    history: [...state.history, targetPageId],
    visitedPageIds: visited,
    savedAt: DateTime.now().toIso8601String(),
  );
  next = applyPageEnter(next, page);
  return next;
}

RunState goBack(RunState state) {
  if (state.history.length < 2) return state;
  final hist = [...state.history]..removeLast();
  return state.copyWith(
    currentPageId: hist.last,
    history: hist,
    savedAt: DateTime.now().toIso8601String(),
  );
}

String adventureStorageKey(String bookId) => 'luditeca-adventure-$bookId';

String getPageLabel(StoryPage page, int index) {
  final title = page.sceneTitle?.trim();
  if (title != null && title.isNotEmpty) return title;
  return 'Página ${page.id}';
}

String endingLabel(String? endingType) {
  switch ((endingType ?? '').toLowerCase()) {
    case 'good':
      return 'Final feliz';
    case 'bad':
      return 'Final infeliz';
    case 'secret':
      return 'Final secreto';
    case 'neutral':
      return 'Final';
    default:
      return 'Fim da história';
  }
}

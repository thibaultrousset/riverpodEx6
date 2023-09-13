import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  runApp(const ProviderScope(
    child: App(),
  ));
}

@immutable
class Film {
  final String id;
  final String title;
  final String description;
  final bool isFavorite;

  const Film(
      {required this.id,
      required this.title,
      required this.description,
      required this.isFavorite});

  Film copy({
    required bool isFavorite,
  }) =>
      Film(
          id: id,
          title: title,
          description: description,
          isFavorite: isFavorite);

  @override
  String toString() {
    return 'Film{id: $id, title: $title, description: $description, isFavorite: $isFavorite}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Film &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isFavorite == other.isFavorite;

  @override
  int get hashCode => Object.hashAll([
        id,
        isFavorite,
      ]);
}

const allFilms = [
  Film(
    id: '1',
    title: 'The Shawshank Redemption',
    description: 'Description',
    isFavorite: false,
  ),
  Film(
    id: '2',
    title: 'The Godfather',
    description: 'Description',
    isFavorite: false,
  ),
  Film(
    id: '3',
    title: 'The Godfather: Part 2',
    description: 'Description',
    isFavorite: false,
  ),
  Film(
    id: '4',
    title: 'The Dark Night',
    description: 'Description',
    isFavorite: false,
  ),
];

class FilmsNotifier extends StateNotifier<List<Film>> {
  FilmsNotifier() : super(allFilms);
  void update(Film film, bool isFavorite) {
    state = state
        .map((filmInList) => filmInList.id == film.id
            ? filmInList.copy(isFavorite: isFavorite)
            : filmInList)
        .toList();
  }
}

enum FavoriteStatus {
  all,
  favorite,
  notFavorite,
}

final favoriteStatusProvider =
    StateProvider<FavoriteStatus>((_) => FavoriteStatus.all);

final allFilmsProvider =
    StateNotifierProvider<FilmsNotifier, List<Film>>((_) => FilmsNotifier());

final favoriteFilmsProvider = Provider((ref) =>
    ref.watch(allFilmsProvider).where((element) => element.isFavorite));

final notFavoriteFilmsProvider = Provider((ref) =>
    ref.watch(allFilmsProvider).where((element) => !element.isFavorite));

class FilmsList extends ConsumerWidget {
  final AlwaysAliveProviderBase<Iterable<Film>> provider;

  const FilmsList({required this.provider, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final films = ref.watch(provider);
    return Expanded(
        child: ListView.builder(
      itemCount: films.length,
      itemBuilder: (context, index) {
        final film = films.elementAt(index);
        final favoriteIcon = film.isFavorite
            ? const Icon(Icons.favorite)
            : const Icon(Icons.favorite_border);
        return ListTile(
          title: Text(film.title),
          subtitle: Text(film.description),
          trailing: IconButton(
            icon: favoriteIcon,
            onPressed: () {
              final isFavorite = !film.isFavorite;
              ref.read(allFilmsProvider.notifier).update(film, isFavorite);
            },
          ),
        );
      },
    ));
  }
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class FilterWidget extends StatelessWidget {
  const FilterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return DropdownButton(
          value: ref.watch(favoriteStatusProvider),
          items: FavoriteStatus.values
              .map((fs) => DropdownMenuItem(
                    value: fs,
                    child: Text(fs.toString().split('.').last),
                  ))
              .toList(),
          onChanged: (FavoriteStatus? fs) {
            ref.read(favoriteStatusProvider.notifier).state = fs!;
          },
        );
      },
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Home Page'),
        ),
        body: Column(
          children: [
            const FilterWidget(),
            Consumer(
              builder: (context, ref, child) {
                final filter = ref.watch(favoriteStatusProvider);
                switch (filter) {
                  case FavoriteStatus.all:
                    return FilmsList(provider: allFilmsProvider);

                  case FavoriteStatus.favorite:
                    return FilmsList(provider: favoriteFilmsProvider);

                  case FavoriteStatus.notFavorite:
                    return FilmsList(provider: notFavoriteFilmsProvider);
                }
              },
            )
          ],
        ));
  }
}

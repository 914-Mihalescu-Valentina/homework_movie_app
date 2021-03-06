import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:homework_movie_app/actions/index.dart';
import 'package:homework_movie_app/containers/filtered_movies_container.dart';
import 'package:homework_movie_app/containers/pending_container.dart';
import 'package:homework_movie_app/containers/user_container.dart';
import 'package:homework_movie_app/main.dart';
import 'package:homework_movie_app/models/index.dart';
import 'package:redux/redux.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    StoreProvider.of<AppState>(context, listen: false)
        .dispatch(GetMovies.start(_onResult));
    _controller.addListener(_onScroll);
  }

  void _onResult(AppAction action) {
    if (action is GetMoviesError) {
      final Object error = action.error;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('An error occurred $error')));
    }
  }

  void _onScroll() {
    final double offset = _controller.offset;
    final double extent = _controller.position.maxScrollExtent;
    final Store<AppState> store = StoreProvider.of<AppState>(context);
    final bool isLoading = <String>[
      GetMovies.pendingKey,
      GetMovies.pendingKeyMore
    ].any(store.state.pending.contains);
    if (offset >= extent - MediaQuery.of(context).size.height && !isLoading) {
      store.dispatch(GetMovies.more(_onResult));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      converter: (Store<AppState> store) => store.state,
      builder: (BuildContext context, AppState state) {
        return FilteredMoviesContainer(
          builder: (BuildContext context, List<Movie> filteredMovies) {
            return Scaffold(
              drawer: Drawer(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        StoreProvider.of<AppState>(context).dispatch(
                          const GetFiltered(1, 'comedy'),
                        );
                        Navigator.pushNamed(context, AppRoutes.filteredMovies);
                      },
                      child: const Text('Comedy'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        StoreProvider.of<AppState>(context).dispatch(
                          const GetFiltered(1, 'drama'),
                        );
                        Navigator.pushNamed(context, AppRoutes.filteredMovies);
                      },
                      child: const Text('Drama'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        StoreProvider.of<AppState>(context).dispatch(
                          const GetFiltered(1, 'animation'),
                        );
                        Navigator.pushNamed(context, AppRoutes.filteredMovies);
                      },
                      child: const Text('Animation'),
                    ),
                  ],
                ),
              ),
              appBar: AppBar(
                title: Center(child: Text('Movies ${state.pageNumber - 1}')),
                actions: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: GestureDetector(
                      onTap: () {
                        StoreProvider.of<AppState>(context)
                            .dispatch(const Logout());
                      },
                      child: const Icon(
                        Icons.power_settings_new,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
              body: PendingContainer(
                builder: (BuildContext context, Set<String> pending) {
                  return Builder(
                    builder: (BuildContext context) {
                      final bool isLoading =
                          state.pending.contains(GetMovies.pendingKey);
                      final bool isLoadingMore =
                          state.pending.contains(GetMovies.pendingKeyMore);
                      if (isLoading && state.movies.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return UserContainer(
                        builder: (BuildContext context, AppUser? user) {
                          return Stack(
                            children: <Widget>[
                              ListView.builder(
                                controller: _controller,
                                itemCount: state.movies.length +
                                    (isLoadingMore ? 1 : 0),
                                itemBuilder: (BuildContext context, int index) {
                                  final Movie movie = state.movies[index];
                                  final bool isFavorite =
                                      user!.favoriteMovies.contains(movie.id);
                                  if (index == state.movies.length) {
                                    return const CircularProgressIndicator();
                                  }
                                  return MovieWidget(
                                      movie: movie, isFavorite: isFavorite);
                                },
                              ),
                              if (state.pending.contains(GetMovies.pendingKey))
                                Positioned(
                                  left: 0,
                                  bottom: 0,
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    height: 80,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                )
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class MovieWidget extends StatelessWidget {
  const MovieWidget({
    Key? key,
    required this.movie,
    required this.isFavorite,
  }) : super(key: key);
  final Movie movie;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        StoreProvider.of<AppState>(context).dispatch(
          SetSelectedMovieId(movie.id),
        );
        Navigator.pushNamed(context, AppRoutes.comments);
      },
      child: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              SizedBox(
                height: 320,
                child: Image.network(
                  movie.poster,
                ),
              ),
              IconButton(
                color: Colors.red,
                onPressed: () {
                  StoreProvider.of<AppState>(
                    context,
                  ).dispatch(
                    UpdateFavorites(
                      movie.id,
                      add: !isFavorite,
                    ),
                  );
                },
                icon: MovieFavoriteIcon(isFavorite: isFavorite),
              )
            ],
          ),
          Text(movie.title),
          Text('${movie.year}'),
          Text(movie.genres.join(',')),
          Text('${movie.rating}')
        ],
      ),
    );
  }
}

class MovieFavoriteIcon extends StatelessWidget {
  const MovieFavoriteIcon({Key? key, required this.isFavorite})
      : super(key: key);
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Icon(
      isFavorite ? Icons.favorite : Icons.favorite_border,
    );
  }
}

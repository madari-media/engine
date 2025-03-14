import 'package:json_annotation/json_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

part 'stremio_addons_types.g.dart';

class ResourceConverter implements JsonConverter<dynamic, dynamic> {
  const ResourceConverter();

  @override
  ResourceObject fromJson(dynamic json) {
    if (json is String) {
      return ResourceObject(
        name: json,
      );
    }
    if (json is Map<String, dynamic>) {
      return ResourceObject.fromJson(json);
    }
    throw ArgumentError('Invalid resource type: $json');
  }

  @override
  dynamic toJson(dynamic object) {
    if (object is String) {
      return object;
    }
    if (object is ResourceObject) {
      return object.toJson();
    }
    throw ArgumentError('Invalid resource type: $object');
  }
}

@JsonSerializable()
class ResourceObject {
  final String name;
  final List<String>? types;
  final List<String>? idPrefixes;
  final List<String>? idPrefix;

  ResourceObject({
    required this.name,
    this.types,
    this.idPrefixes,
    this.idPrefix,
  });

  factory ResourceObject.fromJson(Map<String, dynamic> json) =>
      _$ResourceObjectFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceObjectToJson(this);
}

@JsonSerializable()
class ManifestFeatures {
  String id;

  ManifestFeatures({
    required this.id,
  });

  factory ManifestFeatures.fromJson(Map<String, dynamic> json) {
    return _$ManifestFeaturesFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ManifestFeaturesToJson(this);
}

@JsonSerializable()
class StremioManifest {
  final String id;
  final String name;
  final String? description;
  final List<StremioManifestCatalog>? catalogs;
  final List<String>? idPrefixes;
  final String? icon;
  final String? logo;
  final List<String>? types;
  String? manifestUrl;
  final String? manifestVersion;
  final List<ManifestFeatures>? features;
  final String? madariId;

  @ResourceConverter()
  final List<ResourceObject>? resources;

  StremioManifest({
    required this.id,
    required this.name,
    required this.catalogs,
    this.madariId,
    this.description,
    this.idPrefixes,
    this.resources,
    this.icon,
    this.logo,
    this.features = const [],
    this.types,
    this.manifestVersion,
  });

  factory StremioManifest.fromRecord(RecordModel record, String url) =>
      StremioManifest.fromJson(record.toJson(), url);

  factory StremioManifest.fromJson(
      Map<String, dynamic> json, String manifestUrl) {
    final result = json['resources'] as List<dynamic>;
    final resources = [];

    for (final item in result) {
      if (item is String) {
        final obj = ResourceObject(
          name: item,
        );
        resources.add(obj.toJson());
      } else {
        resources.add(item);
      }
    }

    json['resources'] = resources;

    final manifest = _$StremioManifestFromJson(json);
    manifest.manifestUrl = manifestUrl;

    return manifest;
  }

  Map<String, dynamic> toJson() => _$StremioManifestToJson(this);
}

@JsonSerializable()
class StremioManifestCatalog {
  String type;
  String id;
  String? name;
  @JsonKey(name: "itemCount")
  final int itemCount;
  @JsonKey(name: "pageSize", defaultValue: null)
  final int? pageSize;
  final List<StremioManifestCatalogExtra>? extra;
  @JsonKey(name: "extraRequired")
  final List<String>? extraRequired_;
  @JsonKey(name: "extraSupported")
  final List<String>? extraSupported_;

  bool hasSupport(String feature) {
    return extraSupported?.contains(feature) == true;
  }

  List<String>? get extraRequired {
    final List<String> returnValue = extraRequired_ ?? [];

    if (extra == null) {
      return extraRequired_;
    }

    for (final i in extra!) {
      final result = returnValue.contains(i.name);

      if (i.isRequired == true && !result) {
        returnValue.add(i.name);
      }
    }

    return returnValue;
  }

  List<String>? get extraSupported {
    final List<String> returnValue = extraSupported_ ?? [];

    if (extra == null) {
      return extraSupported_;
    }

    for (final i in extra!) {
      final result = returnValue.contains(i.name);

      if (!result) {
        returnValue.add(i.name);
      }
    }

    return returnValue;
  }

  StremioManifestCatalog({
    required this.id,
    required this.type,
    this.extra,
    this.name,
    this.extraRequired_,
    this.extraSupported_,
    this.itemCount = 50,
    this.pageSize,
  });

  factory StremioManifestCatalog.fromRecord(RecordModel record) =>
      StremioManifestCatalog.fromJson(record.toJson());

  factory StremioManifestCatalog.fromJson(Map<String, dynamic> json) =>
      _$StremioManifestCatalogFromJson(json);

  Map<String, dynamic> toJson() {
    final result = _$StremioManifestCatalogToJson(this);

    result["extraRequired"] = extraRequired;
    result["extraSupported"] = extraSupported;

    return result;
  }
}

@JsonSerializable()
class StremioManifestCatalogExtra {
  final String name;
  final List<dynamic>? options;
  final bool? isRequired;

  StremioManifestCatalogExtra({
    required this.name,
    required this.options,
    this.isRequired,
  });

  factory StremioManifestCatalogExtra.fromJson(Map<String, dynamic> json) {
    try {
      return _$StremioManifestCatalogExtraFromJson(json);
    } catch (e) {
      return StremioManifestCatalogExtra(
        name: "Unable to parse",
        options: [],
      );
    }
  }

  Map<String, dynamic> toJson() => _$StremioManifestCatalogExtraToJson(this);
}

@JsonSerializable()
class StremioConfig {
  List<String> addons;

  StremioConfig({
    required this.addons,
  });

  factory StremioConfig.fromRecord(RecordModel record) =>
      StremioConfig.fromJson(record.toJson());

  factory StremioConfig.fromJson(Map<String, dynamic> json) =>
      _$StremioConfigFromJson(json);

  Map<String, dynamic> toJson() => _$StremioConfigToJson(this);
}

@JsonSerializable()
class StreamMetaResponse {
  final Meta meta;

  StreamMetaResponse({
    required this.meta,
  });

  factory StreamMetaResponse.fromJson(Map<String, dynamic> json) =>
      _$StreamMetaResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StreamMetaResponseToJson(this);
}

@JsonSerializable()
class StrmioMeta {
  @JsonKey(name: "metas")
  final List<Meta>? metas;

  @JsonKey(name: "hasMore")
  final bool? hasMore;

  @JsonKey(name: "cacheMaxAge")
  final int? cacheMaxAge;

  @JsonKey(name: "staleRevalidate")
  final int? staleRevalidate;

  @JsonKey(name: "staleError")
  final int? staleError;

  StrmioMeta({
    required this.metas,
    this.hasMore,
    this.cacheMaxAge,
    this.staleRevalidate,
    this.staleError,
  });

  StrmioMeta copyWith({
    List<Meta>? metas,
    bool? hasMore,
    int? cacheMaxAge,
    int? staleRevalidate,
    int? staleError,
  }) =>
      StrmioMeta(
        metas: metas ?? this.metas,
        hasMore: hasMore ?? this.hasMore,
        cacheMaxAge: cacheMaxAge ?? this.cacheMaxAge,
        staleRevalidate: staleRevalidate ?? this.staleRevalidate,
        staleError: staleError ?? this.staleError,
      );

  factory StrmioMeta.fromJson(Map<String, dynamic> json) =>
      _$StrmioMetaFromJson(json);

  Map<String, dynamic> toJson() => _$StrmioMetaToJson(this);
}

@JsonSerializable()
class Meta {
  @JsonKey(name: "imdb_id")
  final String? imdbId;

  @JsonKey(name: "name")
  final String? name;

  @JsonKey(name: "popularities")
  final Map<String, double?>? popularities;

  @JsonKey(name: "type")
  final String type;

  @JsonKey(name: "cast")
  final List<String>? cast;

  @JsonKey(name: "country")
  final String? country;

  @JsonKey(name: "description")
  final String? description;

  @JsonKey(name: "genre")
  final List<String>? genre;

  @JsonKey(name: "imdbRating")
  final dynamic imdbRating_;

  @JsonKey(name: "tmdbRating")
  final dynamic tmdbRating_;

  @JsonKey(name: "poster")
  String? poster;

  @JsonKey(name: "released")
  final DateTime? released;

  @JsonKey(name: "slug")
  final String? slug;

  @JsonKey(name: "year")
  final dynamic year;

  @JsonKey(name: "status")
  final String? status;

  @JsonKey(name: "tvdb_id")
  final dynamic tvdbId;

  @JsonKey(name: "director")
  final List<dynamic>? director;

  @JsonKey(name: "writer")
  final List<String>? writer;

  @JsonKey(name: "background")
  String? background;

  @JsonKey(name: "logo")
  final String? logo;

  @JsonKey(name: "awards")
  final String? awards;

  @JsonKey(name: "moviedb_id")
  final int? moviedbId;

  @JsonKey(name: "runtime")
  final String? runtime_;

  String? get runtime {
    try {
      if (runtime_ == null) {
        return runtime_;
      }

      return formatTimeFromMinutes(runtime_!);
    } catch (e) {
      return runtime_;
    }
  }

  @JsonKey(name: "trailers")
  final List<Trailer>? trailers;

  @JsonKey(name: "popularity")
  final double? popularity;

  @JsonKey(name: "id")
  final String id;

  @JsonKey(name: "videos")
  List<Video>? videos;

  @JsonKey(name: "genres")
  final List<String>? genres;

  @JsonKey(name: "releaseInfo")
  final dynamic releaseInfo_;

  @JsonKey(name: "trailerStreams")
  final List<TrailerStream>? trailerStreams;

  @JsonKey(name: "links")
  final List<Link>? links;

  @JsonKey(name: "behaviorHints")
  final BehaviorHints? behaviorHints;

  @JsonKey(name: "credits_cast")
  final List<CreditsCast>? creditsCast;

  @JsonKey(name: "credits_crew")
  final List<CreditsCrew>? creditsCrew;

  @JsonKey(name: "language")
  final String? language;

  @JsonKey(name: "dvdRelease")
  final DateTime? dvdRelease;

  final int? traktProgressId;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final double? progress;

  final int? selectedVideoIndex;

  bool? forceRegular = false;

  String get imdbRating {
    return (imdbRating_ ?? "").toString();
  }

  String get tmdbRating {
    return (tmdbRating_ ?? "").toString();
  }

  String get releaseInfo {
    return (releaseInfo_).toString();
  }

  Video? get currentVideo {
    if (type == "movie") {
      return null;
    }

    if (selectedVideoIndex != null) return videos![selectedVideoIndex!];

    return null;
  }

  Meta({
    this.imdbId,
    this.name,
    this.tmdbRating_,
    this.popularities,
    required this.type,
    this.cast,
    this.forceRegular,
    this.country,
    this.description,
    this.selectedVideoIndex,
    this.genre,
    this.imdbRating_,
    this.poster,
    this.released,
    this.slug,
    this.year,
    this.status,
    this.tvdbId,
    this.director,
    this.writer,
    this.background,
    this.logo,
    this.awards,
    this.moviedbId,
    this.runtime_,
    this.trailers,
    this.popularity,
    required this.id,
    this.videos,
    this.genres,
    this.releaseInfo_,
    this.trailerStreams,
    this.links,
    this.behaviorHints,
    this.creditsCast,
    this.creditsCrew,
    this.language,
    this.dvdRelease,
    this.progress,
    this.traktProgressId,
  });

  Meta copyWith({
    String? imdbId,
    String? name,
    Map<String, double>? popularities,
    String? type,
    List<String>? cast,
    String? country,
    String? description,
    List<String>? genre,
    String? imdbRating,
    String? poster,
    DateTime? released,
    String? slug,
    String? year,
    String? status,
    dynamic tvdbId,
    List<dynamic>? director,
    List<String>? writer,
    final dynamic traktInfo,
    String? background,
    String? logo,
    dynamic externalIds,
    dynamic episodeExternalIds,
    String? awards,
    int? moviedbId,
    String? runtime,
    List<Trailer>? trailers,
    double? popularity,
    String? id,
    List<Video>? videos,
    List<String>? genres,
    int? selectedVideoIndex,
    String? releaseInfo,
    List<TrailerStream>? trailerStreams,
    List<Link>? links,
    BehaviorHints? behaviorHints,
    List<CreditsCast>? creditsCast,
    List<CreditsCrew>? creditsCrew,
    String? language,
    DateTime? dvdRelease,
    double? progress,
    bool? forceRegular,
    int? traktProgressId,
    dynamic tmdbRating,
  }) =>
      Meta(
        imdbId: imdbId ?? this.imdbId,
        name: name ?? this.name,
        popularities: popularities ?? this.popularities,
        type: type ?? this.type,
        cast: cast ?? this.cast,
        country: country ?? this.country,
        selectedVideoIndex: selectedVideoIndex ?? this.selectedVideoIndex,
        description: description ?? this.description,
        genre: genre ?? this.genre,
        imdbRating_: imdbRating ?? imdbRating_.toString(),
        poster: poster ?? this.poster,
        released: released ?? this.released,
        traktProgressId: traktProgressId ?? this.traktProgressId,
        slug: slug ?? this.slug,
        year: year ?? this.year,
        forceRegular: forceRegular ?? this.forceRegular,
        status: status ?? this.status,
        tvdbId: tvdbId ?? this.tvdbId,
        director: director ?? this.director,
        writer: writer ?? this.writer,
        background: background ?? this.background,
        logo: logo ?? this.logo,
        awards: awards ?? this.awards,
        moviedbId: moviedbId ?? this.moviedbId,
        runtime_: runtime ?? this.runtime,
        trailers: trailers ?? this.trailers,
        popularity: popularity ?? this.popularity,
        id: id ?? this.id,
        videos: videos ?? this.videos,
        genres: genres ?? this.genres,
        releaseInfo_: releaseInfo ?? this.releaseInfo,
        trailerStreams: trailerStreams ?? this.trailerStreams,
        links: links ?? this.links,
        behaviorHints: behaviorHints ?? this.behaviorHints,
        creditsCast: creditsCast ?? this.creditsCast,
        creditsCrew: creditsCrew ?? this.creditsCrew,
        language: language ?? this.language,
        dvdRelease: dvdRelease ?? this.dvdRelease,
        progress: progress ?? this.progress,
        tmdbRating_: tmdbRating ?? tmdbRating_,
      );

  factory Meta.fromJson(Map<String, dynamic> json) {
    final result = _$MetaFromJson(json);

    return result;
  }

  Map<String, dynamic> toJson() => _$MetaToJson(this);

  @override
  String toString() {
    if (currentVideo != null) {
      return "$name ${currentVideo!.name} S${currentVideo!.season} E${currentVideo!.episode}";
    }
    return name ?? "No name";
  }
}

@JsonSerializable()
class BehaviorHints {
  @JsonKey(name: "defaultVideoId")
  final dynamic defaultVideoId;

  @JsonKey(name: "hasScheduledVideos", defaultValue: false)
  final bool hasScheduledVideos;

  BehaviorHints({
    required this.defaultVideoId,
    required this.hasScheduledVideos,
  });

  BehaviorHints copyWith({
    dynamic defaultVideoId,
    bool? hasScheduledVideos,
  }) =>
      BehaviorHints(
        defaultVideoId: defaultVideoId ?? this.defaultVideoId,
        hasScheduledVideos: hasScheduledVideos ?? this.hasScheduledVideos,
      );

  factory BehaviorHints.fromJson(Map<String, dynamic> json) =>
      _$BehaviorHintsFromJson(json);

  Map<String, dynamic> toJson() => _$BehaviorHintsToJson(this);
}

@JsonSerializable()
class CreditsCast {
  @JsonKey(name: "character")
  final String character;
  @JsonKey(name: "name")
  final String name;
  @JsonKey(name: "profile_path")
  final String? profilePath;
  @JsonKey(name: "id")
  final int id;

  CreditsCast({
    required this.character,
    required this.name,
    required this.profilePath,
    required this.id,
  });

  CreditsCast copyWith({
    String? character,
    String? name,
    String? profilePath,
    int? id,
  }) =>
      CreditsCast(
        character: character ?? this.character,
        name: name ?? this.name,
        profilePath: profilePath ?? this.profilePath,
        id: id ?? this.id,
      );

  factory CreditsCast.fromJson(Map<String, dynamic> json) =>
      _$CreditsCastFromJson(json);

  Map<String, dynamic> toJson() => _$CreditsCastToJson(this);
}

@JsonSerializable()
class CreditsCrew {
  @JsonKey(name: "department")
  final String department;
  @JsonKey(name: "job")
  final String job;
  @JsonKey(name: "name")
  final String name;
  @JsonKey(name: "profile_path")
  final String? profilePath;
  @JsonKey(name: "id")
  final int id;

  CreditsCrew({
    required this.department,
    required this.job,
    required this.name,
    required this.profilePath,
    required this.id,
  });

  CreditsCrew copyWith({
    String? department,
    String? job,
    String? name,
    String? profilePath,
    int? id,
  }) =>
      CreditsCrew(
        department: department ?? this.department,
        job: job ?? this.job,
        name: name ?? this.name,
        profilePath: profilePath ?? this.profilePath,
        id: id ?? this.id,
      );

  factory CreditsCrew.fromJson(Map<String, dynamic> json) =>
      _$CreditsCrewFromJson(json);

  Map<String, dynamic> toJson() => _$CreditsCrewToJson(this);
}

@JsonSerializable()
class Link {
  @JsonKey(name: "name")
  final String? name;
  @JsonKey(name: "category")
  final String? category;
  @JsonKey(name: "url")
  final String? url;

  Link({
    required this.name,
    required this.category,
    required this.url,
  });

  Link copyWith({
    String? name,
    String? category,
    String? url,
  }) =>
      Link(
        name: name ?? this.name,
        category: category ?? this.category,
        url: url ?? this.url,
      );

  factory Link.fromJson(Map<String, dynamic> json) => _$LinkFromJson(json);

  Map<String, dynamic> toJson() => _$LinkToJson(this);
}

@JsonSerializable()
class TrailerStream {
  @JsonKey(name: "title")
  final String title;
  @JsonKey(name: "ytId")
  final String ytId;

  TrailerStream({
    required this.title,
    required this.ytId,
  });

  TrailerStream copyWith({
    String? title,
    String? ytId,
  }) =>
      TrailerStream(
        title: title ?? this.title,
        ytId: ytId ?? this.ytId,
      );

  factory TrailerStream.fromJson(Map<String, dynamic> json) =>
      _$TrailerStreamFromJson(json);

  Map<String, dynamic> toJson() => _$TrailerStreamToJson(this);
}

@JsonSerializable()
class Trailer {
  @JsonKey(name: "source")
  final String source;
  @JsonKey(name: "type")
  final String? type;

  Trailer({
    required this.source,
    required this.type,
  });

  Trailer copyWith({
    String? source,
    String? type,
  }) =>
      Trailer(
        source: source ?? this.source,
        type: type ?? this.type,
      );

  factory Trailer.fromJson(Map<String, dynamic> json) =>
      _$TrailerFromJson(json);

  Map<String, dynamic> toJson() => _$TrailerToJson(this);
}

@JsonSerializable()
class Video {
  @JsonKey(name: "name")
  String? name;
  @JsonKey(name: "season")
  final int? season;
  @JsonKey(name: "number")
  final int? number;
  @JsonKey(name: "firstAired")
  final DateTime? firstAired;
  @JsonKey(name: "tvdb_id")
  int? tvdbId;
  @JsonKey(name: "overview")
  final String? overview;
  @JsonKey(name: "thumbnail")
  final String? thumbnail;
  @JsonKey(name: "id")
  final String id;
  @JsonKey(name: "released")
  final DateTime? released;
  @JsonKey(name: "episode")
  int? episode;
  @JsonKey(name: "description")
  final String? description;
  @JsonKey(name: "title")
  final String? title;
  @JsonKey(name: "moviedb_id")
  final int? moviedbId;
  double? progress;
  dynamic ids;
  @JsonKey(name: "streams")
  final List<VideoStream>? streams;

  Video({
    this.name,
    required this.season,
    required this.number,
    this.firstAired,
    this.tvdbId,
    this.overview,
    this.thumbnail,
    this.streams,
    required this.id,
    this.released,
    this.episode,
    this.description,
    this.title,
    this.moviedbId,
    this.progress,
    this.ids,
  });

  Video copyWith({
    String? name,
    int? season,
    int? number,
    DateTime? firstAired,
    int? tvdbId,
    String? overview,
    String? thumbnail,
    String? id,
    DateTime? released,
    int? episode,
    String? description,
    String? title,
    int? moviedbId,
  }) =>
      Video(
        name: name ?? this.name,
        season: season ?? this.season,
        number: number ?? this.number,
        firstAired: firstAired ?? this.firstAired,
        tvdbId: tvdbId ?? this.tvdbId,
        overview: overview ?? this.overview,
        thumbnail: thumbnail ?? this.thumbnail,
        id: id ?? this.id,
        released: released ?? this.released,
        episode: episode ?? this.episode,
        description: description ?? this.description,
        title: title ?? this.title,
        moviedbId: moviedbId ?? this.moviedbId,
      );

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);

  Map<String, dynamic> toJson() => _$VideoToJson(this);
}

@JsonSerializable()
class StreamResponse {
  @JsonKey(name: "streams")
  final List<VideoStream> streams;

  StreamResponse({
    required this.streams,
  });

  StreamResponse copyWith({
    List<VideoStream>? streams,
  }) =>
      StreamResponse(
        streams: streams ?? this.streams,
      );

  factory StreamResponse.fromJson(Map<String, dynamic> json) =>
      _$StreamResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StreamResponseToJson(this);
}

@JsonSerializable()
class VideoStream {
  @JsonKey(name: "name")
  final String? name;
  @JsonKey(name: "title")
  final String? title;
  @JsonKey(name: "description")
  final String? description;
  @JsonKey(name: "url")
  final String? url;
  @JsonKey(name: "infoHash")
  final String? infoHash;
  @JsonKey(name: "behaviorHints")
  final Map<String, dynamic>? behaviorHints;

  VideoStream({
    this.name,
    this.title,
    this.url,
    required this.behaviorHints,
    this.infoHash,
    this.description,
  });

  VideoStream copyWith({
    String? name,
    String? title,
    String? url,
    String? description,
    Map<String, String>? behaviorHints,
  }) =>
      VideoStream(
        name: name ?? this.name,
        title: title ?? this.title,
        url: url ?? this.url,
        description: description ?? this.description,
        behaviorHints: behaviorHints ?? this.behaviorHints,
      );

  factory VideoStream.fromJson(Map<String, dynamic> json) =>
      _$VideoStreamFromJson(json);

  Map<String, dynamic> toJson() => _$VideoStreamToJson(this);

  @override
  int get hashCode => "$url$name$title$description".length;

  @override
  bool operator ==(Object other) {
    return super.hashCode == other.hashCode;
  }
}

class StreamInfo {
  final String? resolution;
  final String? quality;
  final String? codec;
  final String? audio;
  final String? region;
  final String? container;
  final bool unrated;
  final double? size;

  StreamInfo({
    this.resolution,
    this.quality,
    this.codec,
    this.audio,
    this.region,
    this.container,
    this.unrated = false,
    this.size,
  });
}

class StreamParser {
  static final _resolutionRegex = RegExp(
    '(2160p|1080p|720p|480p|360p|4k|uhd)',
    caseSensitive: false,
  );

  static final _qualityRegex = RegExp(
    '(bluray|bdrip|brrip|webrip|webdl|web-dl|hdrip|dvdrip|hdtv)',
    caseSensitive: false,
  );

  static final _codecRegex = RegExp(
    '(x264|x265|h264|h265|xvid|hevc|mpeg2|mpeg4|vc1|vp8|vp9|av1)',
    caseSensitive: false,
  );

  static final _audioRegex = RegExp(
    '(aac|ac3|dts|dtshd|truehd|dd5\\.1|dd7\\.1|atmos|dts-hd|eac3)',
    caseSensitive: false,
  );

  static final _regionRegex = RegExp(
    '(eur|usa|uk|fr|es|de|it|ru|cn|jp|kor)',
    caseSensitive: false,
  );

  static final _containerRegex = RegExp(
    '(mkv|mp4|avi|wmv|mov|flv|mpg|mpeg)',
    caseSensitive: false,
  );

  static final _unratedRegex = RegExp(
    '(unrated|uncensored)',
    caseSensitive: false,
  );

  static final _sizeRegex = RegExp(
    '(\\d+(?:\\.\\d+)?(?:GB|MB|TB))',
    caseSensitive: false,
  );

  static String getSizeCategory(double? sizeInMB) {
    if (sizeInMB == null) return 'Unknown';
    if (sizeInMB < 500) return '0-500MB';
    if (sizeInMB < 1500) return '500MB-1.5GB';
    if (sizeInMB < 3000) return '1.5GB-3GB';
    if (sizeInMB < 6000) return '3GB-6GB';
    if (sizeInMB < 12000) return '6GB-12GB';
    if (sizeInMB < 20000) return '12GB-20GB';
    return '20GB+';
  }

  static double? parseSize(String? sizeStr) {
    if (sizeStr == null) return null;

    final match = _sizeRegex.firstMatch(sizeStr.toUpperCase());
    if (match == null) return null;

    final value =
        double.tryParse(match.group(1)?.replaceAll(RegExp(r'[A-Z]'), '') ?? '');
    if (value == null) return null;

    if (sizeStr.toUpperCase().contains('GB')) {
      return value * 1024;
    } else if (sizeStr.toUpperCase().contains('TB')) {
      return value * 1024 * 1024;
    }
    return value;
  }

  static StreamInfo parseStreamName(String name) {
    final resMatch = _resolutionRegex.firstMatch(name);
    final qualMatch = _qualityRegex.firstMatch(name);
    final codecMatch = _codecRegex.firstMatch(name);
    final audioMatch = _audioRegex.firstMatch(name);
    final regionMatch = _regionRegex.firstMatch(name);
    final containerMatch = _containerRegex.firstMatch(name);
    final unratedMatch = _unratedRegex.hasMatch(name);
    final sizeMatch = _sizeRegex.firstMatch(name);

    final res = resMatch?.group(1)?.toUpperCase();

    return StreamInfo(
      resolution: res == "2160P" ? "4K" : res,
      quality: qualMatch?.group(1)?.toUpperCase(),
      codec: codecMatch?.group(1)?.toUpperCase(),
      audio: audioMatch?.group(1)?.toUpperCase(),
      region: regionMatch?.group(1)?.toUpperCase(),
      container: containerMatch?.group(1)?.toUpperCase(),
      unrated: unratedMatch,
      size: parseSize(sizeMatch?.group(1)),
    );
  }
}

String formatTimeFromMinutes(String minutesInput) {
  int? minutes = int.tryParse(minutesInput);

  if (minutes == null) {
    return minutesInput;
  }

  int hours = minutes ~/ 60;
  int remainingMinutes = minutes % 60;

  if (hours == 0) {
    return '$remainingMinutes minutes';
  }
  if (remainingMinutes == 0) {
    return '$hours hours';
  }
  return '$hours hours $remainingMinutes minutes';
}

class Trip {
    final String id;
    final String name;
    final String startLocation;
    final String endLocation;
    final String notes;
    final DateTime createdDate;
    final DateTime? startDate;
    final DateTime? endDate;
    final bool isFavorite;

    Trip({
        required this.id,
        required this.name,
        required this.startLocation,
        required this.endLocation,
        required this.notes,
        required this.createdDate,
        this.startDate,
        this.endDate,
        this.isFavorite = false,
    });

    Trip copyWith({
        String? id,
        String? name,
        String? startLocation,
        String? endLocation,
        String? notes,
        DateTime? createdDate,
        DateTime? startDate,
        DateTime? endDate,
        bool? isFavorite,
    }) {
        return Trip(
            id: id ?? this.id,
            name: name ?? this.name,
            startLocation: startLocation ?? this.startLocation,
            endLocation: endLocation ?? this.endLocation,
            notes: notes ?? this.notes,
            createdDate: createdDate ?? this.createdDate,
            startDate: startDate ?? this.startDate,
            endDate: endDate ?? this.endDate,
            isFavorite: isFavorite ?? this.isFavorite,
        );
    }
}
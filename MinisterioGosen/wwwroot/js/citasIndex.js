document.addEventListener("DOMContentLoaded", function () {
    const modalCitaAtendida = document.getElementById("modalCitaAtendida");

    // El modal solo existe cuando TempData["CitaAtendida"] tiene valor.
    if (modalCitaAtendida) {

        const modal = new bootstrap.Modal(modalCitaAtendida);

        modal.show();
    }

});
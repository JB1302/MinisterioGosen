document.addEventListener("DOMContentLoaded", function () {
    const modalCitaExitosa =
        document.getElementById("modalCitaExitosa");

    if (modalCitaExitosa) {

        const modal = new bootstrap.Modal(modalCitaExitosa);

        modal.show();

        // Limpiar formulario cuando se cierre el modal
        modalCitaExitosa.addEventListener(
            "hidden.bs.modal",
            function () {

                const form =
                    document.getElementById("formCita");

                if (form) {
                    form.reset();
                }

            }
        );
    }

});
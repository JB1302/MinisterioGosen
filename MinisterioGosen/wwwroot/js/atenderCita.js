document.addEventListener("DOMContentLoaded", function () {
    const form =
        document.getElementById("formAtenderCita");

    const detalle =
        document.getElementById("Detalle_Cita");

    if (!form || !detalle) {
        return;
    }


    form.addEventListener("submit", function (event) {

        // Limpiar estado anterior de validación
        detalle.classList.remove("is-invalid");

        const valorDetalle = detalle.value.trim();

        if (valorDetalle === "") {

            event.preventDefault();

            detalle.classList.add("is-invalid");

            detalle.focus();

            return;
        }
        if (valorDetalle.length > 500) {

            event.preventDefault();

            detalle.classList.add("is-invalid");

            detalle.focus();

        }

    });

});
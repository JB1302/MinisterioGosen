// =============================================================
// INACTIVAR ACTIVIDAD
// =============================================================

function confirmarInactivarActividad(boton) {

    const nombre = boton.getAttribute("data-nombre");
    const id = boton.getAttribute("data-id");

    Swal.fire({
        title: "Confirmar inactivación",
        text: "¿Desea inactivar la actividad " + nombre +
            "? Dejará de mostrarse a los usuarios, pero no se eliminará del sistema.",
        icon: "warning",
        showCancelButton: true,
        confirmButtonText: "Inactivar",
        cancelButtonText: "Cancelar",
        confirmButtonColor: "#bf8350",
        cancelButtonColor: "#6c757d"
    }).then(function (resultado) {

        if (resultado.isConfirmed) {

            const inputId =
                document.getElementById("inactivarId");

            const formulario =
                document.getElementById("formInactivarActividad");

            if (inputId) {
                inputId.value = id;
            }

            if (formulario) {
                formulario.submit();
            }
        }

    });
}


// =============================================================
// ACTIVAR ACTIVIDAD
// =============================================================

function confirmarActivarActividad(boton) {

    const nombre = boton.getAttribute("data-nombre");
    const id = boton.getAttribute("data-id");

    Swal.fire({
        title: "Confirmar activación",
        text: "¿Desea activar nuevamente la actividad " + nombre + "?",
        icon: "question",
        showCancelButton: true,
        confirmButtonText: "Activar",
        cancelButtonText: "Cancelar",
        confirmButtonColor: "#064442",
        cancelButtonColor: "#6c757d"
    }).then(function (resultado) {

        if (resultado.isConfirmed) {

            const inputId =
                document.getElementById("activarId");

            const formulario =
                document.getElementById("formActivarActividad");

            if (inputId) {
                inputId.value = id;
            }

            if (formulario) {
                formulario.submit();
            }
        }

    });
}
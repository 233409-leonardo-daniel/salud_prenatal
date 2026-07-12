# Guía de integración — Frontend (App móvil)

Audiencia: equipo de la aplicación móvil.
Estado del backend: la app **nunca** habla directo con el microservicio ML; siempre pasa por la
**API principal** (puerto 8000). Los contratos de abajo describen lo que la API principal te va a
entregar (reenviado desde el microservicio ML, puerto 8001).

Este documento cubre **dos funcionalidades nuevas**:

1. **Extracción de síntomas y zonas del cuerpo** desde texto libre (NLP).
2. **Recomendaciones clínicas SOMANZ** (parte de la predicción de riesgo).

---

## 1. NLP — Síntomas + zonas del cuerpo

### 1.1 De dónde viene

La paciente/médico escribe texto libre ("me duele la cabeza y siento hinchados los pies").
La app lo envía a la API principal, que responde con los síntomas y zonas detectados para que
**el médico los revise** antes de guardarlos.

> Las zonas son **opcionales**: puede haber síntomas sin zonas y zonas sin síntoma. No dependas
> de que ambas existan.

### 1.2 Contrato de respuesta

```jsonc
{
  "symptoms": [
    {
      "code": "CEFALEA",              // identificador estable del síntoma
      "label": "Cefalea",             // texto para mostrar
      "raw_text": "me duele la cabeza",// fragmento original del texto
      "negated": false,               // true = la paciente lo NIEGA ("no me duele...")
      "score": 0.83,                  // confianza 0..1
      "alarm": true,                  // true = signo de alarma obstétrica → resáltalo
      "zones": [                      // zonas vinculadas a ESTE síntoma (misma frase). Puede ir vacío.
        { "code": "CABEZA", "label": "Cabeza", "raw_text": "cabeza",
          "negated": false, "score": 0.90 }
      ]
    }
  ],
  "body_zones": [                     // TODAS las zonas detectadas, incluidas las que no se ligaron a un síntoma
    { "code": "CABEZA", "label": "Cabeza", "raw_text": "cabeza",
      "negated": false, "score": 0.90 }
  ],
  "model_version": "symptemist-onnx-int8"
}
```

### 1.3 Cómo renderizar

- **Lista de síntomas:** muestra `label`. Junto a cada uno, si `alarm === true`, pon una marca
  visible (icono/color) — son signos que importan clínicamente.
- **Negación:** si `negated === true`, **no** lo pintes como presente. Muéstralo como "descartado"
  o "la paciente lo niega" (o no lo muestres). Nunca lo trates como síntoma activo.
- **Zonas por síntoma (`symptoms[].zones`):** muéstralas pegadas al síntoma ("Cefalea — zona: Cabeza").
- **Zonas sueltas (`body_zones`):** las zonas que **no** están dentro de ningún `symptoms[].zones`
  se pueden listar aparte como "zonas mencionadas" (útil cuando la paciente nombra una parte del
  cuerpo sin un síntoma claro).
- **`score`:** úsalo solo para orden/umbral visual si quieres; no es obligatorio mostrarlo.

### 1.4 Estados especiales

- **Sin resultados:** `symptoms` y/o `body_zones` pueden venir **vacíos**. Muestra un estado
  "no se detectaron síntomas" y deja que el médico agregue manualmente.
- **Servicio NLP no disponible:** la API principal puede responder que el NLP está caído
  (degradación). En ese caso **no bloquees** el flujo: permite capturar síntomas a mano.

---

## 2. SOMANZ — Recomendaciones clínicas (dentro de la predicción de riesgo)

> **Nuevo:** hoy esta información existe solo en el microservicio ML. Para que llegue a la app,
> la API principal debe reenviarla (ver `main-api.md`). Este apartado describe cómo pintarla.

### 2.1 Cuándo aparece

El endpoint de predicción de riesgo devuelve un campo **`recomendaciones`** **solo cuando el
perfil asignado es Alto Riesgo Hipertensivo / Preeclampsia** (`risk_cluster: 1`). Para los demás
perfiles el campo **no existe** — trátalo como opcional.

### 2.2 Contrato

```jsonc
"recomendaciones": {
  "fuente": "SOMANZ – Prevención de preeclampsia (Parte 3A)",
  "descargo": "Recomendaciones generales de guía clínica ... La decisión final corresponde al médico tratante.",
  "aplica_a_perfil": "Alto Riesgo Hipertensivo / Preeclampsia",
  "items": [
    {
      "intervencion": "Aspirina",
      "recomendacion": "Iniciar aspirina 150 mg/día ...",
      "grade": "1B",                 // calificación de evidencia GRADE (1B, 1C, 2B, 2D...)
      "aplicable_ahora": true,       // depende de la semana gestacional
      "nota": "Ventana de inicio óptima (antes de la semana 16)."
    },
    { "intervencion": "Calcio oral", "recomendacion": "...", "grade": "1C",
      "aplicable_ahora": true, "nota": "..." }
  ],
  "no_recomendados": [
    { "intervencion": "Omega-3 (LCPUFA)", "grade": "2B", "nota": "No recomendado hasta contar con más datos." },
    { "intervencion": "Suplementación con ajo", "grade": "2D", "nota": "No recomendado ..." }
  ]
}
```

### 2.3 Cómo renderizar

- **Muestra `descargo` de forma prominente.** Es un aviso legal: **no es una prescripción**, la
  decisión es del médico. No lo escondas.
- **`items`:** lista cada intervención con su `recomendacion` y su etiqueta `grade`.
  - Si `aplicable_ahora === true`, márcala como aplicable en este momento (por ejemplo, resaltada).
  - Si `aplicable_ahora === false`, muéstrala atenuada y apóyate en `nota` para explicar por qué
    (p. ej. "la ventana de inicio de aspirina ya pasó").
- **`no_recomendados`:** sección secundaria ("no recomendados por evidencia insuficiente").
- **`fuente`:** muéstrala como cita de la guía.

### 2.4 Notas

- El texto de la aspirina cambia según la semana de gestación (se calcula en el backend). Tú solo
  pintas lo que llega; no calcules nada de eso en la app.
- Todo el bloque es opcional: si no viene `recomendaciones`, simplemente no lo muestres.

---

## 3. Checklist de frontend

- [ ] Consumir el nuevo campo `symptoms[].zones` y la lista `body_zones`.
- [ ] Distinguir visualmente `alarm` y `negated`.
- [ ] Manejar respuestas vacías y NLP no disponible sin bloquear el flujo.
- [ ] Renderizar `recomendaciones` SOMANZ solo si viene, con `descargo` visible.
- [ ] Diferenciar `aplicable_ahora` true/false en los items.
